///|
pub enum Token {
  Fn
  Let
  Mut
  If
  Else
  Match
  Case
  While
  For
  In
  Break
  Continue
  Return
  True
  False
  Unit
  Self
  Type
  Struct
  Enum
  Test
  Interface
  Impl
  Pub
  Priv
  Override
  Static
  Virtual
  Abstract
  Underscore
  Ident(String)
  Int(Int)
  UInt(UInt)
  String(String)
  Char(Char)
  Plus
  Minus
  Star
  Slash
  Percent
  Ampersand
  Pipe
  Caret
  Tilde
  Bang
  Question
  Colon
  ColonColon
  Dot
  DotDot
  DotDotDot
  Comma
  Semicolon
  Equal
  PlusEqual
  MinusEqual
  StarEqual
  SlashEqual
  PercentEqual
  AmpersandEqual
  PipeEqual
  CaretEqual
  TildeEqual
  QuestionEqual
  EqEq
  BangEqual
  Lt
  LtEqual
  Gt
  GtEqual
  AmpersandAmpersand
  PipePipe
  LtLt
  GtGt
  LParen
  RParen
  LBracket
  RBracket
  LBrace
  RBrace
  Arrow
  At
  Eof
} derive(Show)

///|
pub struct Lexer {
  input : String
  pos : Int
  line : Int
  column : Int
}

///|
pub fn Lexer::new(input : String) -> Lexer {
  { input, pos: 0, line: 1, column: 1 }
}

///|
fn char_at(s : String, i : Int) -> Char? {
  if i < s.length() {
    let c = s[i]
    c.to_char()
  } else {
    None
  }
}

///|
fn Lexer::current_char(self : Lexer) -> Char? {
  char_at(self.input, self.pos)
}

///|
fn Lexer::advance(self : Lexer) -> Lexer {
  match self.current_char() {
    Some('\n') => { ..self, pos: self.pos + 1, line: self.line + 1, column: 1 }
    Some(_) => { ..self, pos: self.pos + 1, column: self.column + 1 }
    None => self
  }
}

///|
fn is_whitespace(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r'
}

///|
fn is_alpha(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

///|
fn is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///|
fn is_alphanum(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') ||
  (c >= 'A' && c <= 'Z') ||
  (c >= '0' && c <= '9') ||
  c == '_'
}

///|
fn Lexer::skip_whitespace(self : Lexer) -> Lexer {
  let mut lexer = self
  let mut done = false
  while not(done) {
    match char_at(lexer.input, lexer.pos) {
      Some(c) =>
        if is_whitespace(c) {
          lexer = lexer.advance()
        } else {
          done = true
        }
      None => done = true
    }
  }
  lexer
}

///|
fn Lexer::skip_line_comment(self : Lexer) -> Lexer {
  let mut lexer = self
  let mut done = false
  while not(done) {
    match char_at(lexer.input, lexer.pos) {
      Some('\n') | None => done = true
      _ => lexer = lexer.advance()
    }
  }
  lexer
}

///|
fn Lexer::skip_block_comment(self : Lexer) -> Lexer {
  let lexer = self.advance().advance()
  let mut depth = 1
  let mut pos = lexer.pos
  while depth > 0 {
    match char_at(lexer.input, pos) {
      Some('/') =>
        if char_at(lexer.input, pos + 1) == Some('*') {
          depth = depth + 1
          pos = pos + 2
        } else {
          pos = pos + 1
        }
      Some('*') =>
        if char_at(lexer.input, pos + 1) == Some('/') {
          depth = depth - 1
          pos = pos + 2
        } else {
          pos = pos + 1
        }
      Some(_) => pos = pos + 1
      None => depth = 0
    }
  }
  { ..lexer, pos }
}

///|
fn parse_int(s : String) -> Int {
  let mut result = 0
  let mut i = 0
  while i < s.length() {
    let c = s[i]
    if c >= 48 && c <= 57 {
      result = result * 10 + (c - 48).to_int()
    }
    i = i + 1
  }
  result
}

///|
fn Lexer::read_ident(self : Lexer) -> (String, Lexer) {
  let mut lexer = self
  let mut ident = ""
  let mut done = false
  while not(done) {
    match char_at(lexer.input, lexer.pos) {
      Some(c) =>
        if is_alphanum(c) {
          ident = ident + c.to_string()
          lexer = lexer.advance()
        } else {
          done = true
        }
      None => done = true
    }
  }
  (ident, lexer)
}

///|
fn is_keyword(s : String) -> Token {
  match s {
    "fn" => Fn
    "let" => Let
    "mut" => Mut
    "if" => If
    "else" => Else
    "match" => Match
    "case" => Case
    "while" => While
    "for" => For
    "in" => In
    "break" => Break
    "continue" => Continue
    "return" => Return
    "true" => True
    "false" => False
    "unit" => Unit
    "self" => Self
    "type" => Type
    "struct" => Struct
    "enum" => Enum
    "test" => Test
    "interface" => Interface
    "impl" => Impl
    "pub" => Pub
    "priv" => Priv
    "override" => Override
    "static" => Static
    "virtual" => Virtual
    "abstract" => Abstract
    "_" => Underscore
    _ => Ident(s)
  }
}

///|
fn token_eq(a : Token, b : Token) -> Bool {
  match (a, b) {
    (Eof, Eof) => true
    (Fn, Fn) => true
    (Let, Let) => true
    (Mut, Mut) => true
    (If, If) => true
    (Else, Else) => true
    (Match, Match) => true
    (Case, Case) => true
    (While, While) => true
    (For, For) => true
    (In, In) => true
    (Break, Break) => true
    (Continue, Continue) => true
    (Return, Return) => true
    (True, True) => true
    (False, False) => true
    (Unit, Unit) => true
    (Self, Self) => true
    (Type, Type) => true
    (Struct, Struct) => true
    (Enum, Enum) => true
    (Test, Test) => true
    (Interface, Interface) => true
    (Impl, Impl) => true
    (Pub, Pub) => true
    (Priv, Priv) => true
    (Override, Override) => true
    (Static, Static) => true
    (Virtual, Virtual) => true
    (Abstract, Abstract) => true
    (Underscore, Underscore) => true
    (Ident(s1), Ident(s2)) => s1 == s2
    (Int(i1), Int(i2)) => i1 == i2
    (String(s1), String(s2)) => s1 == s2
    (Char(c1), Char(c2)) => c1 == c2
    (Plus, Plus) => true
    (Minus, Minus) => true
    (Star, Star) => true
    (Slash, Slash) => true
    (Percent, Percent) => true
    (Ampersand, Ampersand) => true
    (Pipe, Pipe) => true
    (Caret, Caret) => true
    (Tilde, Tilde) => true
    (Bang, Bang) => true
    (Question, Question) => true
    (Colon, Colon) => true
    (ColonColon, ColonColon) => true
    (Dot, Dot) => true
    (DotDot, DotDot) => true
    (DotDotDot, DotDotDot) => true
    (Comma, Comma) => true
    (Semicolon, Semicolon) => true
    (Equal, Equal) => true
    (PlusEqual, PlusEqual) => true
    (MinusEqual, MinusEqual) => true
    (StarEqual, StarEqual) => true
    (SlashEqual, SlashEqual) => true
    (PercentEqual, PercentEqual) => true
    (AmpersandEqual, AmpersandEqual) => true
    (PipeEqual, PipeEqual) => true
    (CaretEqual, CaretEqual) => true
    (TildeEqual, TildeEqual) => true
    (QuestionEqual, QuestionEqual) => true
    (EqEq, EqEq) => true
    (BangEqual, BangEqual) => true
    (Lt, Lt) => true
    (LtEqual, LtEqual) => true
    (Gt, Gt) => true
    (GtEqual, GtEqual) => true
    (AmpersandAmpersand, AmpersandAmpersand) => true
    (PipePipe, PipePipe) => true
    (LtLt, LtLt) => true
    (GtGt, GtGt) => true
    (LParen, LParen) => true
    (RParen, RParen) => true
    (LBracket, LBracket) => true
    (RBracket, RBracket) => true
    (LBrace, LBrace) => true
    (RBrace, RBrace) => true
    (Arrow, Arrow) => true
    (At, At) => true
    _ => false
  }
}

///|
pub fn Lexer::next_token(self : Lexer) -> (Token, Lexer) {
  let lexer = self.skip_whitespace()
  let c = lexer.current_char()
  
  if c == None {
    return (Eof, lexer)
  }
  
  let c = c.unwrap()
  
  if is_alpha(c) || c == '_' {
    let (ident, lexer2) = lexer.read_ident()
    return (is_keyword(ident), lexer2)
  }
  
  if is_digit(c) {
    let (num_str, lexer2) = lexer.read_ident()
    return (Int(parse_int(num_str)), lexer2)
  }
  
  if c == '"' {
    return lexer.read_string()
  }
  
  if c == '\'' {
    return lexer.read_char()
  }
  
  // Single character tokens
  let lexer2 = lexer.advance()
  let tok = match c {
    '+' => Plus
    '-' => Minus
    '*' => Star
    '/' => Slash
    '%' => Percent
    '&' => Ampersand
    '|' => Pipe
    '^' => Caret
    '~' => Tilde
    '!' => Bang
    '?' => Question
    ':' => Colon
    '.' => Dot
    ',' => Comma
    ';' => Semicolon
    '=' => Equal
    '<' => Lt
    '>' => Gt
    '(' => LParen
    ')' => RParen
    '[' => LBracket
    ']' => RBracket
    '{' => LBrace
    '}' => RBrace
    '@' => At
    _ => Ident("".to_string())
  }
  
  (tok, lexer2)
}

///|
fn Lexer::read_string(self : Lexer) -> (Token, Lexer) {
  let mut lexer = self.advance()
  let mut s = ""
  let mut done = false
  while not(done) {
    match char_at(lexer.input, lexer.pos) {
      Some('"') => {
        lexer = lexer.advance()
        done = true
      }
      Some('\\') => {
        lexer = lexer.advance()
        match char_at(lexer.input, lexer.pos) {
          Some('n') => { s = s + "\n"; lexer = lexer.advance() }
          Some('t') => { s = s + "\t"; lexer = lexer.advance() }
          Some('\\') => { s = s + "\\"; lexer = lexer.advance() }
          Some('"') => { s = s + "\""; lexer = lexer.advance() }
          Some(c) => { s = s + c.to_string(); lexer = lexer.advance() }
          None => done = true
        }
      }
      Some(c) => {
        s = s + c.to_string()
        lexer = lexer.advance()
      }
      None => done = true
    }
  }
  (String(s), lexer)
}

///|
fn Lexer::read_char(self : Lexer) -> (Token, Lexer) {
  let mut lexer = self.advance()
  let mut ch = '?'
  match char_at(lexer.input, lexer.pos) {
    Some('\\') => {
      lexer = lexer.advance()
      match char_at(lexer.input, lexer.pos) {
        Some('n') => { ch = '\n'; lexer = lexer.advance() }
        Some('t') => { ch = '\t'; lexer = lexer.advance() }
        Some('\\') => { ch = '\\'; lexer = lexer.advance() }
        Some('\'') => { ch = '\''; lexer = lexer.advance() }
        Some(c) => { ch = c; lexer = lexer.advance() }
        None => ()
      }
    }
    Some(c) => { ch = c; lexer = lexer.advance() }
    None => ()
  }
  (Char(ch), lexer)
}

///|
pub fn tokenize(input : String) -> Array[Token] {
  let mut lexer = Lexer::new(input)
  let mut tokens : Array[Token] = []
  let mut done = false
  while not(done) {
    let (token, new_lexer) = lexer.next_token()
    tokens = tokens + [token]
    lexer = new_lexer
    if token_eq(token, Eof) {
      done = true
    }
  }
  tokens
}
