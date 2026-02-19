///|
pub enum Type {
  TUnit
  TBool
  TInt
  TFloat
  TString
  TChar
  TFun(Array[Type], Type)
  TTuple(Array[Type])
  TArray(Type)
  TStruct(String, Array[(String, Type)])
  TUnknown
} derive(Show)

///|
pub fn Type::eq(self : Type, other : Type) -> Bool {
  match (self, other) {
    (TUnit, TUnit) => true
    (TBool, TBool) => true
    (TInt, TInt) => true
    (TFloat, TFloat) => true
    (TString, TString) => true
    (TChar, TChar) => true
    (TFun(args1, ret1), TFun(args2, ret2)) =>
      if args1.length() != args2.length() {
        false
      } else {
        let mut eq = ret1.eq(ret2)
        let mut i = 0
        while eq && i < args1.length() {
          eq = args1[i].eq(args2[i])
          i = i + 1
        }
        eq
      }
    (TTuple(ts1), TTuple(ts2)) =>
      if ts1.length() != ts2.length() {
        false
      } else {
        let mut eq = true
        let mut i = 0
        while eq && i < ts1.length() {
          eq = ts1[i].eq(ts2[i])
          i = i + 1
        }
        eq
      }
    (TArray(t1), TArray(t2)) => t1.eq(t2)
    (TStruct(n1, fs1), TStruct(n2, fs2)) =>
      if n1 != n2 {
        false
      } else if fs1.length() != fs2.length() {
        false
      } else {
        let mut eq = true
        let mut i = 0
        while eq && i < fs1.length() {
          let (fn1, ft1) = fs1[i]
          let (fn2, ft2) = fs2[i]
          eq = fn1 == fn2 && ft1.eq(ft2)
          i = i + 1
        }
        eq
      }
    (TUnknown, _) => true
    (_, TUnknown) => true
    _ => false
  }
}

///|
pub struct TypeError {
  message : String
} derive(Show)

///|
pub fn TypeError::new(message : String) -> TypeError {
  { message, }
}

///|
pub struct TypeEnv {
  vars : Map[String, Type]
  funcs : Map[String, (Array[Type], Type)]
  types : Map[String, Type]
}

///|
pub fn TypeEnv::new() -> TypeEnv {
  { vars: Map::new(), funcs: Map::new(), types: Map::new() }
}

///|
fn TypeEnv::add_var(self : TypeEnv, name : String, ty : Type) -> TypeEnv {
  self.vars[name] = ty
  self
}

///|
fn TypeEnv::add_func(
  self : TypeEnv,
  name : String,
  args : Array[Type],
  ret : Type,
) -> TypeEnv {
  self.funcs[name] = (args, ret)
  self
}

///|
fn TypeEnv::get_var(self : TypeEnv, name : String) -> Type {
  match self.vars.get(name) {
    Some(t) => t
    None => TUnknown
  }
}

///|
fn TypeEnv::get_func(self : TypeEnv, name : String) -> (Array[Type], Type)? {
  self.funcs.get(name)
}

///|
fn TypeEnv::add_type(self : TypeEnv, name : String, ty : Type) -> TypeEnv {
  self.types[name] = ty
  self
}

///|
fn TypeEnv::get_type(self : TypeEnv, name : String) -> Type? {
  self.types.get(name)
}

///|
pub struct TypeChecker {
  env : TypeEnv
  errors : Array[TypeError]
}

///|
pub fn TypeChecker::new() -> TypeChecker {
  let env = TypeEnv::new()
  let env = env.add_func("println", [TUnknown], TUnit)
  let env = env.add_func("print", [TUnknown], TUnit)
  let env = env.add_func("input", [], TString)
  let env = env.add_func("int_to_string", [TInt], TString)
  let env = env.add_func("float_to_string", [TFloat], TString)
  let env = env.add_func("string_to_int", [TString], TInt)
  let env = env.add_func("string_to_float", [TString], TFloat)
  let env = env.add_func("char_to_int", [TChar], TInt)
  let env = env.add_func("int_to_char", [TInt], TChar)
  { env, errors: [] }
}

///|
fn TypeChecker::add_error(self : TypeChecker, err : TypeError) -> TypeChecker {
  { ..self, errors: self.errors + [err] }
}

///|
fn TypeChecker::check_expr(
  self : TypeChecker,
  expr : AST,
) -> (TypeChecker, Type) {
  match expr {
    Unit => (self, TUnit)
    Bool(_) => (self, TBool)
    Int(_) => (self, TInt)
    Float(_) => (self, TFloat)
    String(_) => (self, TString)
    Char(_) => (self, TChar)
    Ident(name) => {
      let ty = self.env.get_var(name)
      if ty.eq(TUnknown) {
        (self.add_error(TypeError::new("Unknown variable: \{name}")), TUnknown)
      } else {
        (self, ty)
      }
    }
    Block(stmts) => {
      let mut checker = self
      let mut ty = TUnit
      let mut i = 0
      while i < stmts.length() {
        let (c, t) = checker.check_expr(stmts[i])
        checker = c
        ty = t
        i = i + 1
      }
      (checker, ty)
    }
    Func(name, params, ret_type, body) => {
      let checker = self
      let param_types = params.map(fn(p) {
        match p.1 {
          Some(t) => checker.type_of_ast(t)
          None => TUnknown
        }
      })
      let ret_ty = match ret_type {
        Some(t) => checker.type_of_ast(t)
        None => TUnit
      }
      let mut local_env = checker.env
      let mut j = 0
      while j < params.length() {
        let param_name = params[j].0
        let param_ty = param_types[j]
        local_env = local_env.add_var(param_name, param_ty)
        j = j + 1
      }
      let func_env = { ..checker.env, vars: local_env.vars }
      let checker2 = { ..checker, env: func_env }
      let (c2, _) = checker2.check_expr(body)
      let c3 = { ..c2.env, funcs: c2.env.funcs }
      let c4 = { ..c2, env: c3.add_func(name, param_types, ret_ty) }
      (c4, TFun(param_types, ret_ty))
    }
    LetBind(name, annot, value, body) => {
      let (c2, val_ty) = self.check_expr(value)
      let var_ty = match annot {
        Some(t) => c2.type_of_ast(t)
        None => val_ty
      }
      let c3 = c2.env.add_var(name, var_ty)
      let c4 = { ..c2, env: c3 }
      c4.check_expr(body)
    }
    IfExpr(cond, then, else_branch) => {
      let (c2, cond_ty) = self.check_expr(cond)
      if not(cond_ty.eq(TBool)) {
        let c3 = c2.add_error(
          TypeError::new("Condition must be bool, got: \{cond_ty}"),
        )
        let (c4, then_ty) = c3.check_expr(then)
        match else_branch {
          Some(else_expr) => {
            let (c5, _else_ty) = c4.check_expr(else_expr)
            (c5, then_ty)
          }
          None => (c4, TUnit)
        }
      } else {
        let (c3, then_ty) = c2.check_expr(then)
        match else_branch {
          Some(else_expr) => {
            let (c4, _else_ty) = c3.check_expr(else_expr)
            (c4, then_ty)
          }
          None => (c3, TUnit)
        }
      }
    }
    MatchExpr(expr, cases) => {
      let (c2, _expr_ty) = self.check_expr(expr)
      let mut checker = c2
      let mut result_ty = TUnknown
      let mut i = 0
      while i < cases.length() {
        let (_pattern, body) = cases[i]
        let (c3, body_ty) = checker.check_expr(body)
        checker = c3
        if result_ty.eq(TUnknown) {
          result_ty = body_ty
        }
        i = i + 1
      }
      (checker, result_ty)
    }
    WhileLoop(cond, body) => {
      let (c2, cond_ty) = self.check_expr(cond)
      if not(cond_ty.eq(TBool)) {
        let c3 = c2.add_error(TypeError::new("While condition must be bool"))
        let (c4, _) = c3.check_expr(body)
        (c4, TUnit)
      } else {
        let (c3, _) = c2.check_expr(body)
        (c3, TUnit)
      }
    }
    ForLoop(init, cond, step, body) => {
      let mut checker = self
      match init {
        Some(i) => {
          let (c, _) = checker.check_expr(i)
          checker = c
        }
        None => ()
      }
      match cond {
        Some(c) => {
          let (c2, cond_ty) = checker.check_expr(c)
          if not(cond_ty.eq(TBool)) {
            checker = c2.add_error(TypeError::new("For condition must be bool"))
          } else {
            checker = c2
          }
        }
        None => ()
      }
      match step {
        Some(s) => {
          let (c2, _) = checker.check_expr(s)
          checker = c2
        }
        None => ()
      }
      let (c3, _) = checker.check_expr(body)
      (c3, TUnit)
    }
    ReturnExpr(expr) => {
      let (_, ty) = self.check_expr(expr)
      (self, ty)
    }
    Break => (self, TUnit)
    Continue => (self, TUnit)
    Binary(op, left, right) => {
      let (c2, left_ty) = self.check_expr(left)
      let (c3, right_ty) = c2.check_expr(right)
      let (checker, ty) = match op {
        "+" | "-" | "*" | "/" | "%" =>
          if left_ty.eq(TInt) && right_ty.eq(TInt) {
            (c3, TInt)
          } else if left_ty.eq(TFloat) || right_ty.eq(TFloat) {
            (c3, TFloat)
          } else {
            let c_err = c3.add_error(
              TypeError::new("Operator \{op} requires numeric types"),
            )
            (c_err, TUnknown)
          }
        "==" | "!=" | "<" | ">" | "<=" | ">=" => (c3, TBool)
        "&&" | "||" =>
          if left_ty.eq(TBool) && right_ty.eq(TBool) {
            (c3, TBool)
          } else {
            let c_err = c3.add_error(
              TypeError::new("Logical operators require bool types"),
            )
            (c_err, TBool)
          }
        "<<" | ">>" =>
          if left_ty.eq(TInt) && right_ty.eq(TInt) {
            (c3, TInt)
          } else {
            let c_err = c3.add_error(
              TypeError::new("Bit shift requires int types"),
            )
            (c_err, TUnknown)
          }
        "|" | "^" | "&" =>
          if left_ty.eq(TInt) && right_ty.eq(TInt) {
            (c3, TInt)
          } else {
            let c_err = c3.add_error(
              TypeError::new("Bitwise operators require int types"),
            )
            (c_err, TUnknown)
          }
        _ => (c3, TUnknown)
      }
      (checker, ty)
    }
    Unary(op, expr) => {
      let (c2, expr_ty) = self.check_expr(expr)
      match op {
        "-" =>
          if expr_ty.eq(TInt) {
            (c2, TInt)
          } else if expr_ty.eq(TFloat) {
            (c2, TFloat)
          } else {
            (
              c2.add_error(TypeError::new("Unary minus requires numeric type")),
              TUnknown,
            )
          }
        "!" =>
          if expr_ty.eq(TBool) {
            (c2, TBool)
          } else {
            (
              c2.add_error(TypeError::new("Unary ! requires bool type")),
              TUnknown,
            )
          }
        "~" =>
          if expr_ty.eq(TInt) {
            (c2, TInt)
          } else {
            (
              c2.add_error(TypeError::new("Unary ~ requires int type")),
              TUnknown,
            )
          }
        _ => (c2, TUnknown)
      }
    }
    CallExpr(func, args) => {
      let func_name = match func {
        Ident(name) => Some(name)
        _ => None
      }
      let mut checker = self
      let (c2, func_ty) = checker.check_expr(func)
      checker = c2
      let mut arg_types : Array[Type] = []
      let mut i = 0
      while i < args.length() {
        let (c3, arg_ty) = checker.check_expr(args[i])
        checker = c3
        arg_types = arg_types + [arg_ty]
        i = i + 1
      }
      match func_ty {
        TFun(params, ret) => {
          if params.length() != arg_types.length() {
            checker = checker.add_error(
              TypeError::new(
                "Function call argument count mismatch: expected \{params.length()}, got \{arg_types.length()}",
              ),
            )
          }
          (checker, ret)
        }
        _ =>
          match func_name {
            Some(name) =>
              match checker.env.get_func(name) {
                Some((params, ret)) => {
                  if params.length() != arg_types.length() {
                    checker = checker.add_error(
                      TypeError::new(
                        "Function call argument count mismatch: expected \{params.length()}, got \{arg_types.length()}",
                      ),
                    )
                  }
                  (checker, ret)
                }
                None =>
                  (
                    checker.add_error(
                      TypeError::new("Unknown function: \{name}"),
                    ),
                    TUnknown,
                  )
              }
            None => (checker, TUnknown)
          }
      }
    }
    IndexExpr(arr, index) => {
      let (c2, arr_ty) = self.check_expr(arr)
      let (c3, _idx_ty) = c2.check_expr(index)
      match arr_ty {
        TArray(elem_ty) => (c3, elem_ty)
        _ =>
          (
            c3.add_error(TypeError::new("Cannot index non-array type")),
            TUnknown,
          )
      }
    }
    FieldExpr(expr, _field) => {
      let (c2, _ty) = self.check_expr(expr)
      (c2, TUnknown)
    }
    Tuple(elems) => {
      let mut checker = self
      let mut types : Array[Type] = []
      let mut i = 0
      while i < elems.length() {
        let (c2, ty) = checker.check_expr(elems[i])
        checker = c2
        types = types + [ty]
        i = i + 1
      }
      (checker, TTuple(types))
    }
    ArrayLit(elems) => {
      let mut checker = self
      let mut elem_ty = TUnknown
      let mut i = 0
      while i < elems.length() {
        let (c2, ty) = checker.check_expr(elems[i])
        checker = c2
        if elem_ty.eq(TUnknown) {
          elem_ty = ty
        }
        i = i + 1
      }
      (checker, TArray(elem_ty))
    }
    Assign(lhs, rhs) => {
      let (c2, _lhs_ty) = self.check_expr(lhs)
      let (c3, rhs_ty) = c2.check_expr(rhs)
      (c3, rhs_ty)
    }
    AssignOp(_op, lhs, rhs) => {
      let (c2, _lhs_ty) = self.check_expr(lhs)
      let (c3, rhs_ty) = c2.check_expr(rhs)
      (c3, rhs_ty)
    }
    TypeDecl(name, fields) => {
      let field_types : Array[(String, Type)] = fields.map(fn(f) {
        let (fname, ftype) = f
        let ty = match ftype {
          "Int" => TInt
          "Float" => TFloat
          "Bool" => TBool
          "String" => TString
          "Char" => TChar
          _ => TUnknown
        }
        (fname, ty)
      })
      let struct_ty = TStruct(name, field_types)
      let c2 = self.env.add_type(name, struct_ty)
      ({ ..self, env: c2 }, TUnit)
    }
    StructLit(type_name, fields) => {
      let mut checker = self
      let mut i = 0
      while i < fields.length() {
        let (_fname, fval) = fields[i]
        let (c2, _) = checker.check_expr(fval)
        checker = c2
        i = i + 1
      }
      match checker.env.get_type(type_name) {
        Some(t) => (checker, t)
        None =>
          (
            checker.add_error(TypeError::new("Unknown type: \{type_name}")),
            TUnknown,
          )
      }
    }
  }
}

///|
fn TypeChecker::type_of_ast(self : TypeChecker, ast : AST) -> Type {
  match ast {
    Ident(name) => self.env.get_var(name)
    _ => TUnknown
  }
}

///|
pub fn TypeChecker::check(self : TypeChecker, ast : AST) -> (TypeChecker, Type) {
  self.check_expr(ast)
}
