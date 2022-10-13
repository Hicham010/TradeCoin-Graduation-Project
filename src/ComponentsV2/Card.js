import "./cards.scss";
import ClipLoader from "react-spinners/ClipLoader";

function Card({ title, inputFields, func, loading }) {
  return (
    <div className="l-design-widht">
      <div className="card card--accent">
        <h2>{title}</h2>

        {inputFields.map((item) => {
          return (
            <div key={item[0]}>
              <label className="input">
                <input
                  className="input__field"
                  type="text"
                  placeholder=" "
                  onChange={(e) => item[1](e.target.value)}
                />
                <span className="input__label">{item[0]}</span>
              </label>
            </div>
          );
        })}

        <div className="button-group">
          <button className="button-V2" onClick={func}>
            Create
          </button>
          {showSpinner(loading)}
        </div>
      </div>
    </div>
  );
}

function showSpinner(loading) {
  if (loading === true) {
    return (
      <div className="spinnerDiv">
        <ClipLoader />
      </div>
    );
  }
}

export default Card;
