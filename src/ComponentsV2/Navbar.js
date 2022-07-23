import { Link } from "react-router-dom";

export default function Navbar() {
  return (
    <nav className="nav">
      <Link to="/" className="site-title">
        TradeCoin
      </Link>
      <ul>
        <li>
          <Link to="/tokenizer">Tokenize</Link>
        </li>
        <li>
          <Link to="/commodity">Commodity</Link>
        </li>
        <li>
          <Link to="/composition">Composition</Link>
        </li>
        <li>
          <Link to="/journey">Journey</Link>
        </li>
      </ul>
    </nav>
  );
}
