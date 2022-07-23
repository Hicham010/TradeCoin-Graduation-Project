import "../cards.scss";

const EventLogs = (logs) => {
  // console.log(logs.logs);
  return (
    <div>
      {logs.logs.map((v) => {
        return (
          <div className="card card--accent">
            <EventLog value={v} />
          </div>
        );
      })}
    </div>
  );
};

const EventLog = (value) => {
  return (
    <div>
      {value.value.map((k) => {
        return <div key={k}>{k[0] + ": " + k[1]}</div>;
      })}
      <br />
    </div>
  );
};
export default EventLogs;
