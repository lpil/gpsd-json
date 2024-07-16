import gleam/json
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import gpsd_json.{PollCommand, PollResponse, Tpv, TpvResponse, WatchCommand}

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

pub fn decode_response_poll_0_test() {
  "
  {\"class\":\"POLL\",\"time\":\"2010-06-04T10:31:00.289Z\",\"active\":1,
      \"tpv\":[{\"class\":\"TPV\",\"device\":\"/dev/ttyUSB0\",
              \"time\":\"2010-09-08T13:33:06.095Z\",
              \"ept\":0.005,\"lat\":40.0350930,
              \"lon\":-75.5197487,\"track\":99.4319,\"speed\":0.123,\"mode\":2}],
      \"sky\":[{\"class\":\"SKY\",\"device\":\"/dev/ttyUSB0\",
              \"time\":1270517264.240,\"hdop\":9.20,
              \"satellites\":[{\"PRN\":16,\"el\":55,\"az\":42,\"ss\":36,\"used\":true},
                            {\"PRN\":19,\"el\":25,\"az\":177,\"ss\":0,\"used\":false},
                            {\"PRN\":7,\"el\":13,\"az\":295,\"ss\":0,\"used\":false},
                            {\"PRN\":6,\"el\":56,\"az\":135,\"ss\":32,\"used\":true},
                            {\"PRN\":13,\"el\":47,\"az\":304,\"ss\":0,\"used\":false},
                            {\"PRN\":23,\"el\":66,\"az\":259,\"ss\":0,\"used\":false},
                            {\"PRN\":20,\"el\":7,\"az\":226,\"ss\":0,\"used\":false},
                            {\"PRN\":3,\"el\":52,\"az\":163,\"ss\":32,\"used\":true},
                            {\"PRN\":31,\"el\":16,\"az\":102,\"ss\":0,\"used\":false}
  ]}]}
  "
  |> json.decode(gpsd_json.decode_response)
  |> should.be_ok
  |> should.equal(
    PollResponse(time: "2010-06-04T10:31:00.289Z", active: 1, tpv: [
      Tpv(
        mode: gpsd_json.TwoDimensionalNmeaMode,
        time: Some("2010-09-08T13:33:06.095Z"),
        device: Some("/dev/ttyUSB0"),
        latitude: Some(40.035093),
        longitude: Some(-75.5197487),
      ),
    ]),
  )
}
