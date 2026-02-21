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
  Float(Double)
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
  let mut lexer = self.advance()
  let mut depth = 1
  while depth > 0 {
    match char_at(lexer.input, lexer.pos) {
      Some('/') =>
        if char_at(lexer.input, lexer.pos + 1) == Some('*') {
          depth = depth + 1
          lexer = lexer.advance().advance()
        } else {
          lexer = lexer.advance()
        }
      Some('*') =>
        if char_at(lexer.input, lexer.pos + 1) == Some('/') {
          depth = depth - 1
          lexer = lexer.advance().advance()
        } else {
          lexer = lexer.advance()
        }
      Some(_) => lexer = lexer.advance()
      None => depth = 0
    }
  }
  lexer
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
fn read_while(lexer : Lexer, cond_fn : (Char) -> Bool) -> (String, Lexer) {
  let mut lex = lexer
  let mut result = ""
  let mut done = false
  while not(done) {
    match char_at(lex.input, lex.pos) {
      Some(c) =>
        if cond_fn(c) {
          result = result + c.to_string()
          lex = lex.advance()
        } else {
          done = true
        }
      None => done = true
    }
  }
  (result, lex)
}

///|
fn has_dot(s : String) -> Bool {
  let mut i = 0
  let mut result = false
  while i < s.length() {
    if s[i] == 46 { // '.'
      result = true
    }
    i = i + 1
  }
  result
}

///|
fn has_exp(s : String) -> Bool {
  let mut i = 0
  let mut result = false
  while i < s.length() {
    let c = s[i]
    if c == 101 || c == 69 { // 'e' or 'E'
      result = true
    }
    i = i + 1
  }
  result
}

///|
fn parse_int(s : String) -> Int {
  let mut result = 0
  let mut i = 0
  while i < s.length() {
    let c = s[i]
    if c >= 48 && c <= 57 { // '0' to '9'
      result = result * 10 + (c - 48).to_int()
    }
    i = i + 1
  }
  result
}

///|
fn parse_double(s : String) -> Double {
  let mut result = 0.0
  let mut i = 0
  let mut is_fraction = false
  let mut divisor = 1.0

  while i < s.length() {
    let c = s[i]
    if c == 46 { // '.'
      is_fraction = true
    } else if c >= 48 && c <= 57 { // '0' to '9'
      let digit = (c - 48).to_int()
      if is_fraction {
        divisor = divisor * 10.0
        result = result + digit.to_double() / divisor
      } else {
        result = result * 10.0 + digit.to_double()
      }
    } else if (c == 101 || c == 69) && i < s.length() - 1 {
      // 'e' or 'E'
      // Skip exponent for now - simplified
    }
    i = i + 1
  }
  result
}

///|
fn is_hex_digit(c : Char) -> Bool {
  (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')
}

///|
fn is_binary_digit(c : Char) -> Bool {
  c == '0' || c == '1'
}

///|
fn Lexer::read_number(self : Lexer) -> (String, Lexer) {
  match char_at(self.input, self.pos) {
    Some('0') =>
      match char_at(self.input, self.pos + 1) {
        Some('x') | Some('X') => {
          let lexer = self.advance().advance()
          let mut result = ""
          let mut lex = lexer
          let mut done = false
          while not(done) {
            match char_at(lex.input, lex.pos) {
              Some(c) if is_hex_digit(c) => {
                result = result + c.to_string()
                lex = lex.advance()
              }
              Some('_') => lex = lex.advance()
              _ => done = true
            }
          }
          let val = parse_hex(result)
          (val.to_string(), lex)
        }
        Some('b') | Some('B') => {
          let lexer = self.advance().advance()
          let mut result = ""
          let mut lex = lexer
          let mut done = false
          while not(done) {
            match char_at(lex.input, lex.pos) {
              Some(c) if is_binary_digit(c) => {
                result = result + c.to_string()
                lex = lex.advance()
              }
              Some('_') => lex = lex.advance()
              _ => done = true
            }
          }
          let val = parse_binary(result)
          (val.to_string(), lex)
        }
        _ => self.read_decimal_number()
      }
    _ => self.read_decimal_number()
  }
}

///|
fn parse_hex(s : String) -> Int {
  let mut result = 0
  let mut i = 0
  while i < s.length() {
    let c = s[i]
    let digit = if c >= 48 && c <= 57 {
      c - 48
    } else if c >= 97 && c <= 102 {
      c - 97 + 10
    } else if c >= 65 && c <= 70 {
      c - 65 + 10
    } else {
      0
    }
    result = result * 16 + digit.to_int()
    i = i + 1
  }
  result
}

///|
fn parse_binary(s : String) -> Int {
  let mut result = 0
  let mut i = 0
  while i < s.length() {
    let c = s[i]
    let digit = if c == 48 { 0 } else { 1 }
    result = result * 2 + digit
    i = i + 1
  }
  result
}

///|
fn Lexer::read_decimal_number(self : Lexer) -> (String, Lexer) {
  let mut int_part = ""
  let mut lexer = self
  let mut done = false
  while not(done) {
    match char_at(lexer.input, lexer.pos) {
      Some(c) if is_digit(c) => {
        int_part = int_part + c.to_string()
        lexer = lexer.advance()
      }
      Some('_') => lexer = lexer.advance()
      _ => done = true
    }
  }
  match char_at(lexer.input, lexer.pos) {
    Some('.') => {
      let lexer3 = lexer.advance()
      let mut frac_part = ""
      let mut lex = lexer3
      let mut done = false
      while not(done) {
        match char_at(lex.input, lex.pos) {
          Some(c) if is_digit(c) => {
            frac_part = frac_part + c.to_string()
            lex = lex.advance()
          }
          Some('_') => lex = lex.advance()
          _ => done = true
        }
      }
      match char_at(lex.input, lex.pos) {
        Some('e') | Some('E') => {
          let lexer5 = lex.advance()
          let mut exp_part = ""
          let mut lex2 = lexer5
          let mut done = false
          while not(done) {
            match char_at(lex2.input, lex2.pos) {
              Some(c) if is_digit(c) || c == '-' => {
                exp_part = exp_part + c.to_string()
                lex2 = lex2.advance()
              }
              Some('_') => lex2 = lex2.advance()
              _ => done = true
            }
          }
          (int_part + "." + frac_part + "e" + exp_part, lex2)
        }
        _ => (int_part + "." + frac_part, lex)
      }
    }
    Some('e') | Some('E') => {
      let lexer3 = lexer.advance()
      let mut exp_part = ""
      let mut lex = lexer3
      let mut done = false
      while not(done) {
        match char_at(lex.input, lex.pos) {
          Some(c) if is_digit(c) || c == '-' => {
            exp_part = exp_part + c.to_string()
            lex = lex.advance()
          }
          Some('_') => lex = lex.advance()
          _ => done = true
        }
      }
      (int_part + "e" + exp_part, lex)
    }
    _ => (int_part, lexer)
  }
}

///|
fn Lexer::read_multiline_string(self : Lexer) -> (String, Lexer) {
  let mut lexer = self
  let mut s = ""
  let mut first_line = true
  let mut done = false
  while not(done) {
    match char_at(lexer.input, lexer.pos) {
      Some('#') =>
        if char_at(lexer.input, lexer.pos + 1) == Some('|') {
          lexer = lexer.advance().advance()
          if not(first_line) {
            s = s + "\n"
          }
          first_line = false
          let mut line_done = false
          while not(line_done) {
            match char_at(lexer.input, lexer.pos) {
              Some('\n') => {
                lexer = lexer.advance()
                line_done = true
              }
              Some(c) => {
                s = s + c.to_string()
                lexer = lexer.advance()
              }
              None => {
                line_done = true
                done = true
              }
            }
          }
        } else {
          done = true
        }
      Some(c) =>
        if is_whitespace(c) {
          lexer = lexer.advance()
        } else {
          done = true
        }
      None => done = true
    }
  }
  (s, lexer)
}

///|
fn Lexer::read_string(self : Lexer) -> (String, Lexer) {
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
          Some('n') => {
            s = s + "\n"
            lexer = lexer.advance()
          }
          Some('t') => {
            s = s + "\t"
            lexer = lexer.advance()
          }
          Some('r') => {
            s = s + "\r"
            lexer = lexer.advance()
          }
          Some('\\') => {
            s = s + "\\"
            lexer = lexer.advance()
          }
          Some('"') => {
            s = s + "\""
            lexer = lexer.advance()
          }
          Some(c) => {
            s = s + c.to_string()
            lexer = lexer.advance()
          }
          None => done = true
        }
      }
      Some('\n') => done = true
      Some(c) => {
        s = s + c.to_string()
        lexer = lexer.advance()
      }
      None => done = true
    }
  }
  (s, lexer)
}

///|
fn Lexer::read_char(self : Lexer) -> (Char, Lexer) {
  let mut lexer = self.advance()
  let mut ch = '?'
  match char_at(lexer.input, lexer.pos) {
    Some('\\') => {
      lexer = lexer.advance()
      match char_at(lexer.input, lexer.pos) {
        Some('n') => {
          lexer = lexer.advance()
          ch = '\n'
        }
        Some('t') => {
          lexer = lexer.advance()
          ch = '\t'
        }
        Some('r') => {
          lexer = lexer.advance()
          ch = '\r'
        }
        Some('\\') => {
          lexer = lexer.advance()
          ch = '\\'
        }
        Some('\'') => {
          lexer = lexer.advance()
          ch = '\''
        }
        Some(c) => {
          lexer = lexer.advance()
          ch = c
        }
        None => ch = '?'
      }
    }
    Some(c) => {
      lexer = lexer.advance()
      ch = c
    }
    None => ch = '?'
  }
  match char_at(lexer.input, lexer.pos) {
    Some('\'') => lexer = lexer.advance()
    _ => ()
  }
  (ch, lexer)
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
    (Float(f1), Float(f2)) => f1 == f2
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

  match char_at(lexer.input, lexer.pos) {
    Some(c) =>
      if is_alpha(c) || c == '_' {
        let (ident, lexer2) = lexer.read_ident()
        (is_keyword(ident), lexer2)
      } else if is_digit(c) {
        let (num_str, lexer2) = lexer.read_number()
        let has_dot = has_dot(num_str)
        let has_exp = has_exp(num_str)
        if has_dot || has_exp {
          (Float(parse_double(num_str)), lexer2)
        } else {
          (Int(parse_int(num_str)), lexer2)
        }
      } else if c == '"' {
        let (s, lexer2) = lexer.read_string()
        (String(s), lexer2)
      } else if c == '\'' {
        let (ch, lexer2) = lexer.read_char()
        (Char(ch), lexer2)
      } else if c == '#' && char_at(lexer.input, lexer.pos + 1) == Some('|') {
        let (s, lexer2) = lexer.read_multiline_string()
        (String(s), lexer2)
      } else {
        let lexer2 = lexer.advance()
        match c {
          '+' =>
            if char_at(lexer2.input, lexer2.pos) == Some('=') {
              (PlusEqual, lexer2.advance())
            } else {
              (Plus, lexer2)
            }
          '-' =>
            match char_at(lexer2.input, lexer2.pos) {
              Some('>') => (Arrow, lexer2.advance())
              Some('=') => (MinusEqual, lexer2.advance())
              _ => (Minus, lexer2)
            }
          '*' =>
            if char_at(lexer2.input, lexer2.pos) == Some('=') {
              (StarEqual, lexer2.advance())
            } else {
              (Star, lexer2)
            }
          '/' =>
            match char_at(lexer2.input, lexer2.pos) {
              Some('/') => lexer2.skip_line_comment().next_token()
              Some('*') => lexer2.skip_block_comment().next_token()
              Some('=') => (SlashEqual, lexer2.advance())
              _ => (Slash, lexer2)
            }
          '%' =>
            if char_at(lexer2.input, lexer2.pos) == Some('=') {
              (PercentEqual, lexer2.advance())
            } else {
              (Percent, lexer2)
            }
          '&' =>
            match char_at(lexer2.input, lexer2.pos) {
              Some('&') => (AmpersandAmpersand, lexer2.advance())
              Some('=') => (AmpersandEqual, lexer2.advance())
              _ => (Ampersand, lexer2)
            }
          '|' =>
            match char_at(lexer2.input, lexer2.pos) {
              Some('|') => (PipePipe, lexer2.advance())
              Some('=') => (PipeEqual, lexer2.advance())
              _ => (Pipe, lexer2)
            }
          '^' =>
            if char_at(lexer2.input, lexer2.pos) == Some('=') {
              (CaretEqual, lexer2.advance())
            } else {
              (Caret, lexer2)
            }
          '~' =>
            if char_at(lexer2.input, lexer2.pos) == Some('=') {
              (TildeEqual, lexer2.advance())
            } else {
              (Tilde, lexer2)
            }
          '!' =>
            if char_at(lexer2.input, lexer2.pos) == Some('=') {
              (BangEqual, lexer2.advance())
            } else {
              (Bang, lexer2)
            }
          '?' =>
            if char_at(lexer2.input, lexer2.pos) == Some('=') {
              (QuestionEqual, lexer2.advance())
            } else {
              (Question, lexer2)
            }
          ':' =>
            if char_at(lexer2.input, lexer2.pos) == Some(':') {
              (ColonColon, lexer2.advance())
            } else {
              (Colon, lexer2)
            }
          '.' =>
            if char_at(lexer2.input, lexer2.pos) == Some('.') {
              if char_at(lexer2.input, lexer2.pos + 1) == Some('.') {
                (DotDotDot, lexer2.advance().advance())
              } else {
                (DotDot, lexer2.advance())
              }
            } else {
              (Dot, lexer2)
            }
          ',' => (Comma, lexer2)
          ';' => (Semicolon, lexer2)
          '=' =>
            if char_at(lexer2.input, lexer2.pos) == Some('=') {
              (EqEq, lexer2.advance())
            } else if char_at(lexer2.input, lexer2.pos) == Some('>') {
              (Arrow, lexer2.advance())
            } else {
              (Equal, lexer2)
            }
          '<' =>
            if char_at(lexer2.input, lexer2.pos) == Some('<') {
              if char_at(lexer2.input, lexer2.pos + 1) == Some('=') {
                (LtLt, lexer2.advance().advance())
              } else {
                (LtLt, lexer2.advance())
              }
            } else if char_at(lexer2.input, lexer2.pos) == Some('=') {
              (LtEqual, lexer2.advance())
            } else {
              (Lt, lexer2)
            }
          '>' =>
            if char_at(lexer2.input, lexer2.pos) == Some('>') {
              if char_at(lexer2.input, lexer2.pos + 1) == Some('=') {
                (GtGt, lexer2.advance().advance())
              } else {
                (GtGt, lexer2.advance())
              }
            } else if char_at(lexer2.input, lexer2.pos) == Some('=') {
              (GtEqual, lexer2.advance())
            } else {
              (Gt, lexer2)
            }
          '(' => (LParen, lexer2)
          ')' => (RParen, lexer2)
          '[' => (LBracket, lexer2)
          ']' => (RBracket, lexer2)
          '{' => (LBrace, lexer2)
          '}' => (RBrace, lexer2)
          '@' => (At, lexer2)
          '_' => (Underscore, lexer2)
          _ => (Eof, lexer2)
        }
      }
    None => (Eof, lexer)
  }
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
