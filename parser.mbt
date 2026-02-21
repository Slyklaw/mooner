///|
pub enum AST {
  Unit
  Bool(Bool)
  Int(Int)
  Float(Double)
  String(String)
  Char(Char)
  Ident(String)
  Block(Array[AST])
  Func(String, Array[(String, AST?)], AST?, AST)
  LetBind(String, AST?, AST, AST)
  IfExpr(AST, AST, AST?)
  MatchExpr(AST, Array[(AST, AST)])
  WhileLoop(AST, AST)
  ForLoop(AST?, AST?, AST?, AST)
  ReturnExpr(AST)
  Break
  Continue
  Binary(String, AST, AST)
  Unary(String, AST)
  CallExpr(AST, Array[AST])
  IndexExpr(AST, AST)
  FieldExpr(AST, String)
  Tuple(Array[AST])
  ArrayLit(Array[AST])
  Assign(AST, AST)
  AssignOp(String, AST, AST)
  TypeDecl(String, Array[(String, String)])
  StructLit(String, Array[(String, AST)])
} derive(Show)

///|
pub struct Parser {
  tokens : Array[Token]
  pos : Int
}

///|
pub fn Parser::new(tokens : Array[Token]) -> Parser {
  { tokens, pos: 0 }
}

///|
fn Parser::current(self : Parser) -> Token {
  if self.pos < self.tokens.length() {
    self.tokens[self.pos]
  } else {
    Eof
  }
}

///|
fn Parser::_peek(self : Parser, offset : Int) -> Token {
  let idx = self.pos + offset
  if idx < self.tokens.length() {
    self.tokens[idx]
  } else {
    Eof
  }
}

///|
fn Parser::advance(self : Parser) -> Parser {
  if self.pos < self.tokens.length() - 1 {
    { ..self, pos: self.pos + 1 }
  } else {
    self
  }
}

///|
fn Parser::skip(self : Parser, n : Int) -> Parser {
  let new_pos = self.pos + n
  if new_pos < self.tokens.length() - 1 {
    { ..self, pos: new_pos }
  } else {
    { ..self, pos: self.tokens.length() - 1 }
  }
}

///|
fn self_token_eq(a : Token, b : Token) -> Bool {
  token_eq(a, b)
}

///|
fn Parser::parse_ident(self : Parser) -> (String, Parser) {
  match self.current() {
    Ident(name) => (name, self.advance())
    _ => ("", self)
  }
}

///|
fn Parser::parse_literal(self : Parser) -> (AST, Parser) {
  match self.current() {
    Unit => (Unit, self.advance())
    True => (Bool(true), self.advance())
    False => (Bool(false), self.advance())
    Int(i) => (Int(i), self.advance())
    Float(f) => (Float(f), self.advance())
    String(s) => (String(s), self.advance())
    Char(c) => (Char(c), self.advance())
    Ident(name) => (Ident(name), self.advance())
    LParen => self.parse_tuple_or_parens()
    LBracket => self.parse_array()
    Eof => (Unit, self.advance())
    RBrace => (Unit, self)
    _ => (Unit, self.advance())
  }
}

///|
fn Parser::parse_tuple_or_parens(self : Parser) -> (AST, Parser) {
  let p = self.skip(1)
  if self_token_eq(p.current(), RParen) {
    (Tuple([]), p.advance())
  } else {
    let (first, p2) = p.parse_expr()
    if self_token_eq(p2.current(), RParen) {
      (first, p2.advance())
    } else if self_token_eq(p2.current(), Comma) {
      let p3 = p2.skip(1)
      let mut elems = [first]
      let mut parser = p3
      let mut done = false
      while not(done) {
        let (expr, p2) = parser.parse_expr()
        elems = elems + [expr]
        if self_token_eq(p2.current(), Comma) {
          parser = p2.skip(1)
        } else if self_token_eq(p2.current(), RParen) {
          parser = p2.advance()
          done = true
        } else {
          done = true
        }
      }
      (Tuple(elems), parser)
    } else {
      (first, p2)
    }
  }
}

///|
fn Parser::parse_array(self : Parser) -> (AST, Parser) {
  let p = self.skip(1)
  if self_token_eq(p.current(), RBracket) {
    (ArrayLit([]), p.advance())
  } else {
    let (first, p2) = p.parse_expr()
    if self_token_eq(p2.current(), RBracket) {
      (ArrayLit([first]), p2.advance())
    } else if self_token_eq(p2.current(), Comma) {
      let p3 = p2.skip(1)
      let mut elems = [first]
      let mut parser = p3
      let mut done = false
      while not(done) {
        let (expr, p2) = parser.parse_expr()
        elems = elems + [expr]
        if self_token_eq(p2.current(), Comma) {
          parser = p2.skip(1)
        } else if self_token_eq(p2.current(), RBracket) {
          parser = p2.advance()
          done = true
        } else {
          done = true
        }
      }
      (ArrayLit(elems), parser)
    } else {
      (ArrayLit([first]), p2)
    }
  }
}

///|
fn Parser::parse_primary(self : Parser) -> (AST, Parser) {
  let tok = self.current()
  match tok {
    Ident(_) | Int(_) | Float(_) | String(_) | Char(_) | True | False | Unit =>
      self.parse_literal()
    LParen => self.parse_tuple_or_parens()
    LBracket => self.parse_array()
    If => self.parse_if()
    Match => self.parse_match()
    While => self.parse_while()
    For => self.parse_for()
    Let => self.parse_let()
    Fn => self.parse_function()
    Type => self.parse_type_decl()
    LBrace => self.parse_block()
    Return => {
      let p = self.advance()
      let (expr, p2) = p.parse_expr()
      (ReturnExpr(expr), p2)
    }
    Break => (Break, self.advance())
    Continue => (Continue, self.advance())
    Underscore => (Ident("_".to_string()), self.advance())
    Equal => (Unit, self.advance())
    Eof => (Unit, self.advance())
    RBrace => (Unit, self)
    RParen => (Unit, self)
    Comma => (Unit, self.advance())
    Semicolon => (Unit, self.advance())
    _ => (Unit, self.advance())
  }
}

///|
fn Parser::parse_block(self : Parser) -> (AST, Parser) {
  let p = self.skip(1)
  let mut stmts : Array[AST] = []
  let mut parser = p
  let mut done = false
  while not(done) {
    if self_token_eq(parser.current(), RBrace) {
      parser = parser.advance()
      done = true
    } else if self_token_eq(parser.current(), Eof) {
      done = true
    } else {
      let (stmt, p2) = parser.parse_expr()
      stmts = stmts + [stmt]
      parser = p2
    }
  }
  (Block(stmts), parser)
}

///|
fn Parser::parse_if(self : Parser) -> (AST, Parser) {
  let p = self.skip(1)
  let (cond, p2) = p.parse_expr()
  let (then, p3) = p2.parse_block_or_expr()
  if self_token_eq(p3.current(), Else) {
    let p4 = p3.skip(1)
    if self_token_eq(p4.current(), If) {
      p4.parse_if()
    } else {
      let (else_branch, p5) = p4.parse_block_or_expr()
      (IfExpr(cond, then, Some(else_branch)), p5)
    }
  } else {
    (IfExpr(cond, then, None), p3)
  }
}

///|
fn Parser::parse_match(self : Parser) -> (AST, Parser) {
  let p = self.skip(1)
  let (expr, p2) = p.parse_expr()
  if self_token_eq(p2.current(), LBrace) {
    let p3 = p2.skip(1)
    let mut cases : Array[(AST, AST)] = []
    let mut parser = p3
    let mut done = false
    while not(done) {
      if self_token_eq(parser.current(), RBrace) {
        parser = parser.advance()
        done = true
      } else if self_token_eq(parser.current(), Case) {
        let p2 = parser.skip(1)
        let (pattern, p3) = p2.parse_expr()
        if self_token_eq(p3.current(), Arrow) {
          let p4 = p3.skip(1)
          let (body, p5) = p4.parse_block_or_expr()
          cases = cases + [(pattern, body)]
          parser = p5
        } else {
          parser = p3
        }
      } else {
        parser = parser.advance()
      }
    }
    (MatchExpr(expr, cases), parser)
  } else {
    (MatchExpr(expr, []), p2)
  }
}

///|
fn Parser::parse_while(self : Parser) -> (AST, Parser) {
  let p = self.skip(1)
  let (cond, p2) = p.parse_expr()
  let (body, p3) = p2.parse_block_or_expr()
  (WhileLoop(cond, body), p3)
}

///|
fn Parser::parse_for(self : Parser) -> (AST, Parser) {
  let p = self.skip(1)
  // Check if there's a '(' or if it's a simple identifier (for i = ...)
  let has_paren = self_token_eq(p.current(), LParen)
  let p_after_paren = if has_paren { p.skip(1) } else { p }

  // Parse init (can be let-binding, assignment, or empty)
  let (init, p2) = if self_token_eq(p_after_paren.current(), Semicolon) {
    (None, p_after_paren.skip(1))
  } else if self_token_eq(p_after_paren.current(), Let) {
    // let binding
    let (expr, p4) = p_after_paren.parse_let()
    if self_token_eq(p4.current(), Semicolon) {
      (Some(expr), p4.skip(1))
    } else {
      (Some(expr), p4)
    }
  } else {
    // Could be an identifier = value (for loop variable) or other expression
    let (expr, p4) = p_after_paren.parse_expr()
    // Check if this is an assignment to an undeclared variable (for loop init)
    let init_expr = match expr {
      Assign(Ident(name), value) =>
        // Convert to LetBind for the loop scope
        // We'll use Unit as the body since it's just initialization
        LetBind(name, None, value, Unit)
      _ => expr
    }
    if self_token_eq(p4.current(), Semicolon) {
      (Some(init_expr), p4.skip(1))
    } else {
      (Some(init_expr), p4)
    }
  }

  // Parse condition
  let (cond, p3) = if self_token_eq(p2.current(), Semicolon) {
    (None, p2.skip(1))
  } else {
    let (expr, p4) = p2.parse_expr()
    if self_token_eq(p4.current(), Semicolon) {
      (Some(expr), p4.skip(1))
    } else {
      (Some(expr), p4)
    }
  }

  // Parse step (either until ')' or until '{')
  let (step, p4) = if has_paren {
    if self_token_eq(p3.current(), RParen) {
      (None, p3.advance())
    } else {
      let (expr, p5) = p3.parse_expr()
      if self_token_eq(p5.current(), RParen) {
        (Some(expr), p5.advance())
      } else {
        (Some(expr), p5)
      }
    }
    // No parentheses - step goes until '{'
  } else if self_token_eq(p3.current(), LBrace) {
    (None, p3)
  } else {
    let (expr, p5) = p3.parse_expr()
    (Some(expr), p5)
  }

  let (body, p5) = p4.parse_block_or_expr()
  (ForLoop(init, cond, step, body), p5)
}

///|
fn Parser::parse_let(self : Parser) -> (AST, Parser) {
  let p = self.skip(1)
  let is_mut = self_token_eq(p.current(), Mut)
  let p_after_mut = if is_mut { p.skip(1) } else { p }
  let (name, p2) = p_after_mut.parse_ident()
  let (annot, p3) = if self_token_eq(p2.current(), Colon) {
    let p4 = p2.skip(1)
    let (t, p5) = p4.parse_type()
    (Some(t), p5)
  } else {
    (None, p2)
  }
  if self_token_eq(p3.current(), Equal) {
    let p4 = p3.skip(1)
    let (value, p5) = p4.parse_expr()
    let (body, p6) = p5.parse_expr()
    (LetBind(name, annot, value, body), p6)
  } else {
    (LetBind(name, annot, Unit, Unit), p3)
  }
}

///|
fn Parser::parse_function(self : Parser) -> (AST, Parser) {
  let p = self.skip(1)
  let (name, p2) = p.parse_ident()
  if self_token_eq(p2.current(), LParen) {
    let (params, p3) = p2.parse_params()
    let (ret_type, p4) = if self_token_eq(p3.current(), Arrow) {
      let p5 = p3.skip(1)
      let (t, p6) = p5.parse_type()
      (Some(t), p6)
    } else {
      (None, p3)
    }
    let (body, p5) = p4.parse_block_or_expr()
    (Func(name, params, ret_type, body), p5)
  } else {
    let p3 = p2
    if self_token_eq(p3.current(), LBrace) {
      let (body, p4) = p3.parse_block()
      (Func(name, [], None, body), p4)
    } else {
      (Func(name, [], None, Unit), p3)
    }
  }
}

///|
fn Parser::parse_type_decl(self : Parser) -> (AST, Parser) {
  // type Name { field1: Type1, field2: Type2 }
  let p = self.skip(1)
  let (name, p2) = p.parse_ident()
  if self_token_eq(p2.current(), LBrace) {
    let p3 = p2.skip(1)
    let mut fields : Array[(String, String)] = []
    let mut parser = p3
    let mut done = false
    while not(done) {
      if self_token_eq(parser.current(), RBrace) {
        parser = parser.advance()
        done = true
      } else if self_token_eq(parser.current(), Eof) {
        done = true
      } else {
        let (field_name, p4) = parser.parse_ident()
        let (field_type, p5) = if self_token_eq(p4.current(), Colon) {
          let p6 = p4.skip(1)
          let (t, p7) = p6.parse_type_name()
          (t, p7)
        } else {
          ("Int", p4)
        }
        fields = fields + [(field_name, field_type)]
        if self_token_eq(p5.current(), Comma) {
          parser = p5.skip(1)
        } else if self_token_eq(p5.current(), RBrace) {
          parser = p5.advance()
          done = true
        } else {
          parser = p5
        }
      }
    }
    (TypeDecl(name, fields), parser)
  } else {
    (TypeDecl(name, []), p2)
  }
}

///|
fn Parser::parse_type_name(self : Parser) -> (String, Parser) {
  match self.current() {
    Ident(name) => {
      let p = self.advance()
      if self_token_eq(p.current(), LBracket) {
        let p2 = p.skip(1)
        let (inner, p3) = p2.parse_type_name()
        if self_token_eq(p3.current(), RBracket) {
          ("\{name}[\{inner}]", p3.advance())
        } else {
          ("\{name}[\{inner}]", p3)
        }
      } else if self_token_eq(p.current(), LtLt) {
        let p2 = p.skip(1)
        let (inner, p3) = p2.parse_type_name()
        ("\{name}<\{inner}>", p3)
      } else {
        (name, p)
      }
    }
    _ => ("Int", self)
  }
}

///|
fn Parser::parse_params(self : Parser) -> (Array[(String, AST?)], Parser) {
  let p = self.skip(1)
  if self_token_eq(p.current(), RParen) {
    ([], p.advance())
  } else {
    let (first_name, p2) = p.parse_ident()
    let (first_annot, p3) = if self_token_eq(p2.current(), Colon) {
      let p4 = p2.skip(1)
      let (t, p5) = p4.parse_type()
      (Some(t), p5)
    } else {
      (None, p2)
    }
    let first = (first_name, first_annot)
    let mut params = [first]
    let mut parser = p3
    let mut done = false
    while not(done) {
      if self_token_eq(parser.current(), Comma) {
        let p2 = parser.skip(1)
        let (n, p3) = p2.parse_ident()
        let (a, p4) = if self_token_eq(p3.current(), Colon) {
          let p5 = p3.skip(1)
          let (t, p6) = p5.parse_type()
          (Some(t), p6)
        } else {
          (None, p3)
        }
        params = params + [(n, a)]
        parser = p4
      } else if self_token_eq(parser.current(), RParen) {
        parser = parser.advance()
        done = true
      } else {
        done = true
      }
    }
    (params, parser)
  }
}

///|
fn Parser::parse_type(self : Parser) -> (AST, Parser) {
  match self.current() {
    Ident(name) => {
      let p = self.advance()
      if self_token_eq(p.current(), LBracket) {
        let p2 = p.skip(1)
        let (inner, p3) = p2.parse_type()
        let inner_name = match inner {
          Ident(n) => n
          _ => "Unknown"
        }
        if self_token_eq(p3.current(), RBracket) {
          (Ident("\{name}[\{inner_name}]"), p3.advance())
        } else {
          (Ident("\{name}[\{inner_name}]"), p3)
        }
      } else {
        (Ident(name), p)
      }
    }
    LParen => self.parse_type_tuple()
    _ => (Ident("Unknown"), self)
  }
}

///|
fn Parser::parse_type_tuple(self : Parser) -> (AST, Parser) {
  let p = self.skip(1)
  if self_token_eq(p.current(), RParen) {
    (Ident("Unit"), p.advance())
  } else {
    let (first, p2) = p.parse_type()
    if self_token_eq(p2.current(), RParen) {
      (first, p2.advance())
    } else if self_token_eq(p2.current(), Comma) {
      let p3 = p2.skip(1)
      let mut types = [first]
      let mut parser = p3
      let mut done = false
      while not(done) {
        let (t, p2) = parser.parse_type()
        types = types + [t]
        if self_token_eq(p2.current(), Comma) {
          parser = p2.skip(1)
        } else if self_token_eq(p2.current(), RParen) {
          parser = p2.advance()
          done = true
        } else if self_token_eq(p2.current(), Arrow) {
          done = true
        } else {
          done = true
        }
      }
      (Tuple(types), parser)
    } else if self_token_eq(p2.current(), Arrow) {
      let p3 = p2.skip(1)
      let (ret, p4) = p3.parse_type()
      (Ident("(\{first})->\{ret}"), p4)
    } else {
      (first, p2)
    }
  }
}

///|
fn Parser::parse_block_or_expr(self : Parser) -> (AST, Parser) {
  if self_token_eq(self.current(), LBrace) {
    self.parse_block()
  } else {
    self.parse_expr()
  }
}

///|
fn Parser::parse_postfix(self : Parser) -> (AST, Parser) {
  let (base, p2) = self.parse_primary()
  let mut expr = base
  let mut parser = p2
  let mut done = false
  while not(done) {
    if self_token_eq(parser.current(), LParen) {
      let (args, p3) = parser.parse_args()
      expr = CallExpr(expr, args)
      parser = p3
    } else if self_token_eq(parser.current(), ColonColon) {
      // Struct literal: TypeName::{ field: value, ... }
      let type_name = match expr {
        Ident(name) => name
        _ => ""
      }
      let p3 = parser.skip(1)
      if self_token_eq(p3.current(), LBrace) {
        let p4 = p3.skip(1)
        let mut fields : Array[(String, AST)] = []
        let mut p5 = p4
        let mut done2 = false
        while not(done2) {
          if self_token_eq(p5.current(), RBrace) {
            p5 = p5.advance()
            done2 = true
          } else if self_token_eq(p5.current(), Eof) {
            done2 = true
          } else {
            let (field_name, p6) = p5.parse_ident()
            let (field_val, p7) = if self_token_eq(p6.current(), Colon) {
              let p8 = p6.skip(1)
              let (v, p9) = p8.parse_expr()
              (v, p9)
            } else {
              (Unit, p6)
            }
            fields = fields + [(field_name, field_val)]
            if self_token_eq(p7.current(), Comma) {
              p5 = p7.skip(1)
            } else if self_token_eq(p7.current(), RBrace) {
              p5 = p7.advance()
              done2 = true
            } else {
              p5 = p7
            }
          }
        }
        expr = StructLit(type_name, fields)
        parser = p5
      } else {
        parser = p3
      }
    } else if self_token_eq(parser.current(), Dot) {
      let p3 = parser.skip(1)
      // Check for numeric field (tuple index) or identifier
      match p3.current() {
        Int(i) => {
          expr = FieldExpr(expr, i.to_string())
          parser = p3.advance()
        }
        _ => {
          let (field, p4) = p3.parse_ident()
          expr = FieldExpr(expr, field)
          parser = p4
        }
      }
    } else if self_token_eq(parser.current(), LBracket) {
      let p3 = parser.skip(1)
      let (index, p4) = p3.parse_expr()
      if self_token_eq(p4.current(), RBracket) {
        expr = IndexExpr(expr, index)
        parser = p4.advance()
      } else {
        parser = p4
      }
    } else {
      done = true
    }
  }
  (expr, parser)
}

///|
fn Parser::parse_args(self : Parser) -> (Array[AST], Parser) {
  let p = self.skip(1)
  if self_token_eq(p.current(), RParen) {
    ([], p.advance())
  } else {
    let (first, p2) = p.parse_expr()
    let mut args = [first]
    let mut parser = p2
    let mut done = false
    while not(done) {
      if self_token_eq(parser.current(), Comma) {
        let p2 = parser.skip(1)
        let (arg, p3) = p2.parse_expr()
        args = args + [arg]
        parser = p3
      } else if self_token_eq(parser.current(), RParen) {
        parser = parser.advance()
        done = true
      } else {
        done = true
      }
    }
    (args, parser)
  }
}

///|
fn Parser::parse_unary(self : Parser) -> (AST, Parser) {
  let tok = self.current()
  if self_token_eq(tok, Bang) {
    let p = self.skip(1)
    let (expr, p2) = p.parse_unary()
    (Unary("!", expr), p2)
  } else if self_token_eq(tok, Minus) {
    let p = self.skip(1)
    let (expr, p2) = p.parse_unary()
    (Unary("-", expr), p2)
  } else if self_token_eq(tok, Tilde) {
    let p = self.skip(1)
    let (expr, p2) = p.parse_unary()
    (Unary("~", expr), p2)
  } else if self_token_eq(tok, Ampersand) {
    let p = self.skip(1)
    let (expr, p2) = p.parse_unary()
    (Unary("&", expr), p2)
  } else {
    self.parse_postfix()
  }
}

///|
fn parse_bin_prec(op : String) -> Int {
  match op {
    "||" => 1
    "&&" => 2
    "|" => 3
    "^" => 4
    "&" => 5
    "==" | "!=" => 6
    "<" | ">" | "<=" | ">=" => 7
    "<<" | ">>" => 8
    "+" | "-" => 9
    "*" | "/" | "%" => 10
    _ => 0
  }
}

///|
fn is_binop(tok : Token) -> Bool {
  match tok {
    Plus
    | Minus
    | Star
    | Slash
    | Percent
    | Ampersand
    | Pipe
    | Caret
    | Lt
    | Gt
    | LtEqual
    | GtEqual
    | EqEq
    | BangEqual
    | AmpersandAmpersand
    | PipePipe
    | LtLt
    | GtGt => true
    _ => false
  }
}

///|
fn binop_to_str(tok : Token) -> String {
  match tok {
    Plus => "+"
    Minus => "-"
    Star => "*"
    Slash => "/"
    Percent => "%"
    Ampersand => "&"
    Pipe => "|"
    Caret => "^"
    Lt => "<"
    Gt => ">"
    LtEqual => "<="
    GtEqual => ">="
    EqEq => "=="
    BangEqual => "!="
    AmpersandAmpersand => "&&"
    PipePipe => "||"
    LtLt => "<<"
    GtGt => ">>"
    _ => ""
  }
}

///|
fn Parser::parse_binary(self : Parser, min_prec : Int) -> (AST, Parser) {
  let (left, p2) = self.parse_unary()
  let mut parser = p2
  let mut left_expr = left
  let mut done = false
  while not(done) {
    let tok = parser.current()
    if is_binop(tok) {
      let op = binop_to_str(tok)
      let prec = parse_bin_prec(op)
      if prec >= min_prec {
        let p3 = parser.skip(1)
        let (right, p4) = p3.parse_binary(prec + 1)
        left_expr = Binary(op, left_expr, right)
        parser = p4
      } else {
        done = true
      }
    } else {
      done = true
    }
  }
  (left_expr, parser)
}

///|
fn Parser::parse_expr(self : Parser) -> (AST, Parser) {
  let (left, p2) = self.parse_binary(1)
  // Check for assignment
  if self_token_eq(p2.current(), Equal) {
    let p3 = p2.skip(1)
    let (value, p4) = p3.parse_expr()
    (Assign(left, value), p4)
  } else {
    // Check for compound assignment operators
    let op = match p2.current() {
      PlusEqual => Some("+")
      MinusEqual => Some("-")
      StarEqual => Some("*")
      SlashEqual => Some("/")
      PercentEqual => Some("%")
      AmpersandEqual => Some("&")
      PipeEqual => Some("|")
      CaretEqual => Some("^")
      LtLt => Some("<<")
      GtGt => Some(">>")
      _ => None
    }
    match op {
      Some(op_str) => {
        let p3 = p2.skip(1)
        let (value, p4) = p3.parse_expr()
        (AssignOp(op_str, left, value), p4)
      }
      None => (left, p2)
    }
  }
}

///|
pub fn Parser::parse(self : Parser) -> AST {
  let mut stmts : Array[AST] = []
  let mut parser = self
  let mut done = false
  while not(done) {
    if self_token_eq(parser.current(), Eof) {
      done = true
    } else {
      let (expr, p2) = parser.parse_expr()
      stmts = stmts + [expr]
      parser = p2
    }
  }
  if stmts.length() == 1 {
    stmts[0]
  } else {
    Block(stmts)
  }
}

///|
pub fn parse(tokens : Array[Token]) -> AST {
  let parser = Parser::new(tokens)
  parser.parse()
}
