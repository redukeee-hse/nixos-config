# Observability stack from the Go course (lecture 04-observability):
# OpenTelemetry Collector, Prometheus, Grafana, Loki and Jaeger, wired the
# same way as the course lab and on the same ports, so the course Makefile,
# dashboard and links work unchanged.
#
#   app ── OTLP/HTTP :22318 ──► Collector ──► Jaeger (traces)
#                                         ──► Loki   (logs)
#                               Collector ◄── scrape ── Prometheus (metrics)
#   Grafana :22300 ──► Prometheus :22909 / Jaeger :22686 / Loki :3100
#
# Everything listens on localhost only and nothing starts at boot: run
# `obs-up` when needed and `obs-down` afterwards. `obs-env > .env` writes the
# OTEL_* variables the course example expects. Members of `wheel` may start
# and stop these units without a password.
{ lib, pkgs, ... }:

let
  jaeger = pkgs.callPackage ../../packages/jaeger { };

  units = [
    "opentelemetry-collector.service"
    "prometheus.service"
    "grafana.service"
    "loki.service"
    "jaeger.service"
  ];

  ports = {
    otlpHttp = 22318;    # Collector, where apps send traces, metrics and logs
    grafana = 22300;
    prometheus = 22909;
    jaegerUi = 22686;
    jaegerOtlp = 24317;  # Collector -> Jaeger, OTLP/gRPC
    jaegerGrpc = 16685;  # Jaeger query API (gRPC)
    loki = 3100;
    lokiGrpc = 9096;
    collectorMetrics = 8889;  # Prometheus exporter, scraped by Prometheus
  };

  jaegerConfig = (pkgs.formats.yaml { }).generate "jaeger.yaml" {
    service = {
      extensions = [ "jaeger_storage" "jaeger_query" ];
      pipelines.traces = {
        receivers = [ "otlp" ];
        processors = [ "batch" ];
        exporters = [ "jaeger_storage_exporter" ];
      };
      # Its own metrics would otherwise take :8888.
      telemetry.metrics.level = "none";
    };
    extensions = {
      jaeger_storage.backends.memstore.memory.max_traces = 100000;
      jaeger_query = {
        storage.traces = "memstore";
        http.endpoint = "127.0.0.1:${toString ports.jaegerUi}";
        grpc.endpoint = "127.0.0.1:${toString ports.jaegerGrpc}";
      };
    };
    receivers.otlp.protocols.grpc.endpoint = "127.0.0.1:${toString ports.jaegerOtlp}";
    processors.batch = { };
    exporters.jaeger_storage_exporter.trace_storage = "memstore";
  };

  envFile = pkgs.writeShellScriptBin "obs-env" ''
    cat <<'ENV'
    OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:${toString ports.otlpHttp}
    OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
    OTEL_RESOURCE_ATTRIBUTES=service.namespace=tripgo
    OTEL_METRIC_EXPORT_INTERVAL=5000
    ENV
  '';

  mkCtl = name: action:
    pkgs.writeShellScriptBin name ''
      exec systemctl ${action} ${lib.concatStringsSep " " units}
    '';
in
{
  services.opentelemetry-collector = {
    enable = true;
    package = pkgs.opentelemetry-collector-contrib;
    settings = {
      receivers.otlp.protocols.http.endpoint = "127.0.0.1:${toString ports.otlpHttp}";
      processors.batch = { };
      exporters = {
        "otlp/jaeger" = {
          endpoint = "127.0.0.1:${toString ports.jaegerOtlp}";
          tls.insecure = true;
        };
        "otlphttp/loki".endpoint = "http://127.0.0.1:${toString ports.loki}/otlp";
        prometheus.endpoint = "127.0.0.1:${toString ports.collectorMetrics}";
      };
      service = {
        pipelines = {
          traces = { receivers = [ "otlp" ]; processors = [ "batch" ]; exporters = [ "otlp/jaeger" ]; };
          metrics = { receivers = [ "otlp" ]; processors = [ "batch" ]; exporters = [ "prometheus" ]; };
          logs = { receivers = [ "otlp" ]; processors = [ "batch" ]; exporters = [ "otlphttp/loki" ]; };
        };
        telemetry.metrics.level = "none";
      };
    };
  };

  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = ports.prometheus;
    retentionTime = "7d";
    globalConfig = {
      scrape_interval = "5s";
      evaluation_interval = "5s";
    };
    # The course queries use job="otel-collector"; the app's own job ends up
    # in exported_job, e.g. "tripgo/order-service".
    scrapeConfigs = [{
      job_name = "otel-collector";
      static_configs = [{ targets = [ "127.0.0.1:${toString ports.collectorMetrics}" ]; }];
    }];
  };

  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;
      server = {
        http_listen_address = "127.0.0.1";
        http_listen_port = ports.loki;
        grpc_listen_address = "127.0.0.1";
        grpc_listen_port = ports.lokiGrpc;
      };
      common = {
        path_prefix = "/var/lib/loki";
        replication_factor = 1;
        instance_addr = "127.0.0.1";
        ring.kvstore.store = "inmemory";
        storage.filesystem = {
          chunks_directory = "/var/lib/loki/chunks";
          rules_directory = "/var/lib/loki/rules";
        };
      };
      schema_config.configs = [{
        from = "2024-01-01";
        store = "tsdb";
        object_store = "filesystem";
        schema = "v13";
        index = { prefix = "index_"; period = "24h"; };
      }];
      limits_config.allow_structured_metadata = true;
      analytics.reporting_enabled = false;
    };
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = ports.grafana;
        domain = "localhost";
      };
      # Local learning instance only, never reachable from the network.
      security.secret_key = "local-observability-lab";
      # Like the course lab: anonymous Admin, so the dashboard import script
      # works without a login; admin/admin for the login form.
      "auth.anonymous" = {
        enabled = true;
        org_role = "Admin";
      };
      analytics.reporting_enabled = false;
    };
    # The course dashboard refers to these data sources by uid.
    provision.datasources.settings = {
      apiVersion = 1;
      datasources = [
        {
          name = "Prometheus";
          uid = "prometheus";
          type = "prometheus";
          url = "http://127.0.0.1:${toString ports.prometheus}";
          isDefault = true;
        }
        {
          name = "Jaeger";
          uid = "jaeger";
          type = "jaeger";
          url = "http://127.0.0.1:${toString ports.jaegerUi}";
        }
        {
          name = "Loki";
          uid = "loki";
          type = "loki";
          url = "http://127.0.0.1:${toString ports.loki}";
          # TraceID -> View trace in Jaeger, from the trace_id structured metadata.
          jsonData.derivedFields = [{
            name = "TraceID";
            matcherType = "label";
            matcherRegex = "trace_id";
            datasourceUid = "jaeger";
            url = "\${__value.raw}";
          }];
        }
      ];
    };
  };

  systemd.services.jaeger = {
    description = "Jaeger tracing (in-memory)";
    after = [ "network.target" ];
    # Otherwise Jaeger traces its own queries to localhost:4317 and floods
    # the journal with connection errors.
    environment.OTEL_TRACES_SAMPLER = "always_off";
    serviceConfig = {
      ExecStart = "${lib.getExe jaeger} --config ${jaegerConfig}";
      DynamicUser = true;
      Restart = "on-failure";
    };
  };

  # Start on demand only.
  systemd.services.opentelemetry-collector.wantedBy = lib.mkForce [ ];
  systemd.services.prometheus.wantedBy = lib.mkForce [ ];
  systemd.services.grafana.wantedBy = lib.mkForce [ ];
  systemd.services.loki.wantedBy = lib.mkForce [ ];

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          ${builtins.toJSON units}.indexOf(action.lookup("unit")) >= 0 &&
          subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  environment.systemPackages = [
    pkgs.opentelemetry-collector-contrib  # otelcol-contrib validate ...
    pkgs.prometheus                       # promtool
    pkgs.grafana-loki                     # logcli
    jaeger
    envFile
    (mkCtl "obs-up" "start")
    (mkCtl "obs-down" "stop")
  ];
}
