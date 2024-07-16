import gleam/json
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import gpsd_json.{PollCommand, Tpv, TpvResponse, WatchCommand}

pub fn main() {
  gleeunit.main()
}

pub fn command_to_string_watch_0_test() {
  WatchCommand(enable: Some(True), json: Some(False))
  |> gpsd_json.command_to_string
  |> should.equal("?WATCH={\"enable\":true,\"json\":false};")
}

pub fn command_to_string_watch_1_test() {
  WatchCommand(enable: Some(False), json: None)
  |> gpsd_json.command_to_string
  |> should.equal("?WATCH={\"enable\":false};")
}

pub fn command_to_string_watch_2_test() {
  WatchCommand(enable: None, json: None)
  |> gpsd_json.command_to_string
  |> should.equal("?WATCH={};")
}

pub fn command_to_string_poll_test() {
  PollCommand
  |> gpsd_json.command_to_string
  |> should.equal("?POLL;")
}

pub fn decode_response_tpv_0_test() {
  "
  {\"class\":\"TPV\",\"device\":\"/dev/pts/1\",
    \"time\":\"2005-06-08T10:34:48.283Z\",\"ept\":0.005,
    \"lat\":46.498293369,\"lon\":7.567411672,\"alt\":1343.127,
    \"eph\":36.000,\"epv\":32.321,
    \"track\":10.3788,\"speed\":0.091,\"climb\":-0.085,\"mode\":3}
  "
  |> json.decode(gpsd_json.decode_response)
  |> should.be_ok
  |> should.equal(
    TpvResponse(Tpv(
      mode: gpsd_json.ThreeDimensionalNmeaMode,
      time: Some("2005-06-08T10:34:48.283Z"),
      device: Some("/dev/pts/1"),
      latitude: Some(46.498293369),
      longitude: Some(7.567411672),
    )),
  )
}

pub fn decode_response_tpv_1_test() {
  "
  {\"class\":\"TPV\",\"device\":\"/dev/pts/3\",
    \"time\":\"2005-06-08T10:34:48.283Z\",\"ept\":0.005,
    \"eph\":36.000,\"epv\":32.321,
    \"track\":10.3788,\"speed\":0.091,\"climb\":-0.085,\"mode\":3}
  "
  |> json.decode(gpsd_json.decode_response)
  |> should.be_ok
  |> should.equal(
    TpvResponse(Tpv(
      mode: gpsd_json.ThreeDimensionalNmeaMode,
      time: Some("2005-06-08T10:34:48.283Z"),
      device: Some("/dev/pts/3"),
      latitude: None,
      longitude: None,
    )),
  )
}

pub fn decode_response_tpv_2_test() {
  "
  {\"class\":\"TPV\",\"mode\":1}
  "
  |> json.decode(gpsd_json.decode_response)
  |> should.be_ok
  |> should.equal(
    TpvResponse(Tpv(
      mode: gpsd_json.NoFixNmeaMode,
      time: None,
      device: None,
      latitude: None,
      longitude: None,
    )),
  )
}
