import { Link } from "react-router-dom";
import "./cards.scss";

export default function Navbar() {
  return (
    <nav className="nav">
      <Link to="/" className="site-title" style={{ width: "50%" }}>
        TradeCoin
      </Link>
      <ul>
        <li style={{ width: "100%", fontSize: "1em" }}>
          <Link to="/tokenizer">Tokenize</Link>
        </li>
        <li style={{ width: "100%", fontSize: "1em" }}>
          <Link to="/commodity">Commodity</Link>
        </li>
        <li style={{ width: "100%", fontSize: "1em" }}>
          <Link to="/composition">Composition</Link>
        </li>
        <li style={{ width: "100%", fontSize: "1em" }}>
          <Link to="/journey">Journey</Link>
        </li>
      </ul>
    </nav>
  );
}
