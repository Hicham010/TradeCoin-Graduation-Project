import { Link } from "react-router-dom";
import "./cards.scss";

export default function Navbar() {
  return (
    <nav className="nav">
      <Link to="/" className="site-title" style={{ width: "50%" }}>
        TradeCoin
      </Link>
      <ul>
        <li style={{ width: "50%" }}>
          <Link to="/tokenizer">Tokenize</Link>
        </li>
        <li style={{ width: "50%" }}>
          <Link to="/commodity">Commodity</Link>
        </li>
        <li style={{ width: "50%" }}>
          <Link to="/composition">Composition</Link>
        </li>
        <li style={{ width: "50%" }}>
          <Link to="/journey">Journey</Link>
        </li>
      </ul>
    </nav>
  );
}
