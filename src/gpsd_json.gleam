//// Types and functions for working with GPSD's JSON API.
////
//// <https://gpsd.io/gpsd_json.html>
////
//// This library does not cover the full API presently, instead it only covers
//// basic parts of the API that I wanted for my project. Pull requests to add
//// support for parts that you want are very welcome!

import decode
import gleam/dynamic
import gleam/json
import gleam/option.{type Option}

pub type Command {
  /// This command sets watcher mode.
  ///
  /// <https://gpsd.io/gpsd_json.html#_watch>
  WatchCommand(
    /// Enable (true) or disable (false) watcher mode.
    enable: Option(Bool),
    /// Enable (true) or disable (false) dumping of JSON reports.
    json: Option(Bool),
  )

  /// The POLL command requests data from the last-seen fixes on all active GPS
  /// devices. Devices must previously have been activated by ?WATCH to be
  /// pollable.
  ///
  /// <https://gpsd.io/gpsd_json.html#_poll>
  PollCommand
}

pub fn command_to_string(command: Command) -> String {
  case command {
    PollCommand -> "?POLL;"

    WatchCommand(enable: enable, json: json) -> {
      let options =
        [
          option.map(enable, fn(enabled) { #("enable", json.bool(enabled)) }),
          option.map(json, fn(json) { #("json", json.bool(json)) }),
        ]
        |> option.values
        |> json.object
        |> json.to_string
      "?WATCH=" <> options <> ";"
    }
  }
}

pub type Response {
  /// A TPV object is a time-position-velocity report.
  ///
  /// <https://gpsd.io/gpsd_json.html#_tpv>
  TpvResponse(Tpv)

  /// Response to the POLL command.
  ///
  /// <https://gpsd.io/gpsd_json.html#_poll>
  PollResponse(
    /// Timestamp in ISO 8601 format. May have a fractional part of up to .001sec
    /// precision.
    time: String,
    /// Count of active devices.
    active: Int,
    tpv: List(Tpv),
  )

  OtherResponse(class: String)
}

pub fn decode_response(
  data: dynamic.Dynamic,
) -> Result(Response, List(dynamic.DecodeError)) {
  decode.from(response_decoder(), data)
}

pub fn response_decoder() -> decode.Decoder(Response) {
  decode.at(["class"], decode.string)
  |> decode.then(fn(class) {
    case class {
      "TPV" -> tpv_decoder() |> decode.map(TpvResponse)
      "POLL" -> poll_decoder()
      _ -> decode.into(OtherResponse(class: class))
    }
  })
}

fn poll_decoder() -> decode.Decoder(Response) {
  decode.into({
    use time <- decode.parameter
    use active <- decode.parameter
    use tpv <- decode.parameter
    PollResponse(time: time, active: active, tpv: tpv)
  })
  |> decode.field("time", decode.string)
  |> decode.field("active", decode.int)
  |> decode.field("tpv", decode.list(tpv_decoder()))
}

fn tpv_decoder() -> decode.Decoder(Tpv) {
  decode.into({
    use mode <- decode.parameter
    use device <- decode.parameter
    use time <- decode.parameter
    use latitude <- decode.parameter
    use longitude <- decode.parameter
    Tpv(
      mode: mode,
      device: device,
      time: time,
      latitude: latitude,
      longitude: longitude,
    )
  })
  |> decode.field("mode", nmea_mode_decoder())
  |> decode.field("device", decode.optional(decode.string))
  |> decode.field("time", decode.optional(decode.string))
  |> decode.field("lat", decode.optional(decode.float))
  |> decode.field("lon", decode.optional(decode.float))
}

fn nmea_mode_decoder() -> decode.Decoder(NmeaMode) {
  decode.int
  |> decode.then(fn(i) {
    case i {
      0 -> decode.into(UnknownNmeaMode)
      1 -> decode.into(NoFixNmeaMode)
      2 -> decode.into(TwoDimensionalNmeaMode)
      3 -> decode.into(ThreeDimensionalNmeaMode)
      _ -> decode.fail("NMEA Mode")
    }
  })
}

pub type Tpv {
  Tpv(
    mode: NmeaMode,
    /// The name of the originating device
    device: Option(String),
    /// Time/date stamp in ISO8601 format, UTC. May have a fractional part of up
    /// to .001sec precision. May be absent if the mode is not 2D or 3D. May be
    /// present, but invalid, if there is no fix. Verify 3 consecutive 3D fixes
    /// before believing it is UTC. Even then it may be off by several seconds
    /// until the current leap seconds is known.
    time: Option(String),
    /// Latitude in degrees: +/- signifies North/South.
    latitude: Option(Float),
    /// Longitude in degrees: +/- signifies East/West.
    longitude: Option(Float),
  )
}

pub type NmeaMode {
  UnknownNmeaMode
  NoFixNmeaMode
  TwoDimensionalNmeaMode
  ThreeDimensionalNmeaMode
}
