{ config, pkgs, ... }:
{
  services.mpd = {
    enable = true;
    musicDirectory = config.xdg.userDirs.music;
    network.startWhenNeeded = true;
    extraConfig = ''
      auto_update "yes"
      restore_paused "yes"
      follow_outside_symlinks "yes"
      follow_inside_symlinks "yes"

      audio_output {
        type "pulse"
        name "PulseAudio / PipeWire"
      }
    '';
  };

  systemd.user.services.mpdris2-rs = {
    Unit = {
      Description = "Music Player Daemon MPRIS bridge";
      Wants = [ "mpd.service" ];
      After = [ "mpd.service" ];
    };
    Service = {
      Type = "dbus";
      BusName = "org.mpris.MediaPlayer2.mpd";
      ExecStart = "${pkgs.mpdris2-rs}/bin/mpdris2-rs --host /run/user/1000/mpd/socket";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
