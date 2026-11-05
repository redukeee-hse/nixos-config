# Redis and a single-node Kafka (KRaft) for learning. Both listen on
# localhost only and do not start at boot: run `redis-up` / `kafka-up` when
# needed and `redis-down` / `kafka-down` afterwards. Members of `wheel` may
# start and stop these two units without a password.
{ lib, pkgs, ... }:

let
  units = [ "redis.service" "apache-kafka.service" ];

  mkCtl = name: action: unit:
    pkgs.writeShellScriptBin name ''
      exec systemctl ${action} ${unit}
    '';
in
{
  # The unnamed server gets the unit `redis.service`, 127.0.0.1:6379.
  services.redis.servers."" = {
    enable = true;
    bind = "127.0.0.1";
    port = 6379;
  };
  systemd.services.redis.wantedBy = lib.mkForce [ ];

  services.apache-kafka = {
    enable = true;
    clusterId = "gMRDYEgLRTO4KWjKREhKUg";
    formatLogDirs = true;
    # Java otherwise reserves a quarter of RAM for the heap.
    jvmOptions = [ "-Xms256m" "-Xmx512m" ];
    settings = {
      "node.id" = 1;
      "process.roles" = [ "broker" "controller" ];
      "listeners" = [
        "PLAINTEXT://127.0.0.1:9092"
        "CONTROLLER://127.0.0.1:9093"
      ];
      "advertised.listeners" = [ "PLAINTEXT://127.0.0.1:9092" ];
      "listener.security.protocol.map" = [
        "PLAINTEXT:PLAINTEXT"
        "CONTROLLER:PLAINTEXT"
      ];
      "controller.listener.names" = [ "CONTROLLER" ];
      "controller.quorum.voters" = [ "1@127.0.0.1:9093" ];
      "log.dirs" = [ "/var/lib/apache-kafka" ];
      # A single broker cannot hold more than one replica of anything.
      "offsets.topic.replication.factor" = 1;
      "transaction.state.log.replication.factor" = 1;
      "transaction.state.log.min.isr" = 1;
      "num.partitions" = 1;
    };
  };
  systemd.services.apache-kafka.wantedBy = lib.mkForce [ ];

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
    pkgs.redis        # redis-cli
    pkgs.apacheKafka  # kafka-topics.sh, kafka-console-producer.sh, ...
    (mkCtl "redis-up" "start" "redis.service")
    (mkCtl "redis-down" "stop" "redis.service")
    (mkCtl "kafka-up" "start" "apache-kafka.service")
    (mkCtl "kafka-down" "stop" "apache-kafka.service")
  ];
}
