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
      Description = "MPD MPRIS bridge";
      Wants = [ "mpd.socket" ];
      After = [ "mpd.socket" ];
    };
    Service = {
      Type = "dbus";
      BusName = "org.mpris.MediaPlayer2.mpd";
      ExecStart = "${pkgs.mpdris2-rs}/bin/mpdris2-rs --host %t/mpd/socket --no-notification";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
