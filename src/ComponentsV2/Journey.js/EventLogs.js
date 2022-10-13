import "../cards.scss";

const EventLogs = (logs) => {
  // console.log("Logs: ", logs.logs);
  return (
    <div>
      {logs.logs.map((v, i) => {
        // console.log("v", v);
        return (
          <div className="card card--accent" key={v[0] + i}>
            <EventLog value={v} key={v[0]} />
          </div>
        );
      })}
    </div>
  );
};

const EventLog = (value) => {
  // console.log("value", value);
  return (
    <div>
      {value.value.map((k) => {
        return <div key={`${k[0]},${k[1]}`}>{`${k[0]}: ${k[1]}`}</div>;
      })}
      <br />
    </div>
  );
};
export default EventLogs;
