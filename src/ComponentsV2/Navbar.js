export default function Navbar() {
  return (
    <nav className="nav">
      <a href="/" className="site-title">
        TradeCoin{" "}
      </a>
      <ul>
        <li>
          <a href="/TradeCoin-Graduation-Project/tokenizer">Tokenize</a>
        </li>
        <li>
          <a href="/TradeCoin-Graduation-Project/commodity">Commodity</a>
        </li>
        <li>
          <a href="/TradeCoin-Graduation-Project/composition">Composition</a>
        </li>
        <li>
          <a href="/TradeCoin-Graduation-Project/journey">Journey</a>
        </li>
      </ul>
    </nav>
  );
}
