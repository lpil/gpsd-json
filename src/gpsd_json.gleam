//// Types and functions for working with GPSD's JSON API.
////
//// <https://gpsd.io/gpsd_json.html>
////
//// This library does not cover the full API presently, instead it only covers
//// basic parts of the API that I wanted for my project. Pull requests to add
//// support for parts that you want are very welcome!

import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None}

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

pub fn response_decoder() -> decode.Decoder(Response) {
  decode.at(["class"], decode.string)
  |> decode.then(fn(class) {
    case class {
      "TPV" -> tpv_decoder() |> decode.map(TpvResponse)
      "POLL" -> poll_decoder()
      _ -> decode.success(OtherResponse(class: class))
    }
  })
}

fn poll_decoder() -> decode.Decoder(Response) {
  use time <- decode.field("time", decode.string)
  use active <- decode.field("active", decode.int)
  use tpv <- decode.field("tpv", decode.list(tpv_decoder()))
  decode.success(PollResponse(time: time, active: active, tpv: tpv))
}

fn tpv_decoder() -> decode.Decoder(Tpv) {
  use mode <- decode.field("mode", nmea_mode_decoder())
  use device <- decode.optional_field(
    "device",
    None,
    decode.optional(decode.string),
  )
  use time <- decode.optional_field(
    "time",
    None,
    decode.optional(decode.string),
  )
  use latitude <- decode.optional_field(
    "lat",
    None,
    decode.optional(decode.float),
  )
  use longitude <- decode.optional_field(
    "lon",
    None,
    decode.optional(decode.float),
  )
  decode.success(Tpv(
    mode: mode,
    device: device,
    time: time,
    latitude: latitude,
    longitude: longitude,
  ))
}

fn nmea_mode_decoder() -> decode.Decoder(NmeaMode) {
  decode.int
  |> decode.then(fn(i) {
    case i {
      0 -> decode.success(UnknownNmeaMode)
      1 -> decode.success(NoFixNmeaMode)
      2 -> decode.success(TwoDimensionalNmeaMode)
      3 -> decode.success(ThreeDimensionalNmeaMode)
      _ -> decode.failure(UnknownNmeaMode, "NMEA Mode")
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
