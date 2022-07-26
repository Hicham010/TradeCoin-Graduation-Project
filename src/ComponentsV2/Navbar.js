// import { Link } from "react-router-dom";

export default function Navbar() {
  return (
    <nav className="nav">
      <a href="/#/" className="site-title">
        TradeCoin
      </a>
      <ul>
        <li>
          <a href="/#/tokenizer">Tokenize</a>
        </li>
        <li>
          <a href="/#/commodity">Commodity</a>
        </li>
        <li>
          <a href="/#/composition">Composition</a>
        </li>
        <li>
          <a href="/#/journey">Journey</a>
        </li>
      </ul>
    </nav>
  );
}
