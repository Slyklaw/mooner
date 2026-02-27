///|
pub enum Operand {
  Imm(Int)
  Reg(String)
  Stack(Int)
  Label(String)
  LabelAddr(String)
} derive(Show)

///|
pub enum X86Inst {
  Mov(X86Operand, X86Operand)
  Movzx(X86Operand, X86Operand)
  Push(X86Operand)
  Pop(X86Operand)
  Add(X86Operand, X86Operand)
  Sub(X86Operand, X86Operand)
  Imul(X86Operand, X86Operand)
  Idiv(X86Operand)
  Cmp(X86Operand, X86Operand)
  Test(X86Operand, X86Operand)
  And(X86Operand, X86Operand)
  Or(X86Operand, X86Operand)
  Xor(X86Operand, X86Operand)
  Not(X86Operand)
  Neg(X86Operand)
  Inc(X86Operand)
  Dec(X86Operand)
  Cqo
  Shl(X86Operand, X86Operand)
  Shr(X86Operand, X86Operand)
  Sar(X86Operand, X86Operand)
  Jmp(String)
  Je(String)
  Jne(String)
  Jg(String)
  Jge(String)
  Jl(String)
  Jle(String)
  Ja(String)
  Jae(String)
  Jb(String)
  Jbe(String)
  Jz(String)
  Jnz(String)
  Jp(String)
  Setz(X86Operand)
  Setnz(X86Operand)
  Setg(X86Operand)
  Setge(X86Operand)
  Setl(X86Operand)
  Setle(X86Operand)
  Seta(X86Operand)
  Setae(X86Operand)
  Setb(X86Operand)
  Setbe(X86Operand)
  PushXmm(String)
  PopXmm(String)
  Call(String)
  Ret
  Nop
  Syscall
  Lea(X86Operand, X86Operand)
  Movsd(X86Operand, X86Operand)
  Addsd(X86Operand, X86Operand)
  Subsd(X86Operand, X86Operand)
  Mulsd(X86Operand, X86Operand)
  Divsd(X86Operand, X86Operand)
  Ucomisd(X86Operand, X86Operand)
  Cvtsi2sd(X86Operand, X86Operand)
  Cvttsd2si(X86Operand, X86Operand)
  RepMovsq
} derive(Show)

///|
pub enum X86Operand {
  Imm8(Int)
  Imm32(Int)
  Imm64(Int)
  Reg8(String)
  Reg32(String)
  Reg64(String)
  Xmm(String)
  Stack8(Int)
  Stack32(Int)
  Stack64(Int)
  StackBP64(Int)
  RipRel32(String)
  Label(String)
  MemIndirect(String)
  MemOffset(String, Int) // base register, offset
} derive(Show)

///|
pub struct CodeGen {
  code : Array[Byte]
  labels : Map[String, Int]
  pending_labels : Array[(String, Int)]
  label_counter : Int
  var_offsets : Map[String, Int]
  var_is_float : Map[String, Bool]
  var_is_string : Map[String, Bool]
  var_is_char : Map[String, Bool]
  var_is_bool : Map[String, Bool]
  var_is_tuple : Map[String, Bool]
  var_is_map : Map[String, Bool]
  var_tuple_field_types : Map[String, Array[Bool]]
  var_array_len : Map[String, Int]
  var_types : Map[String, String]
  var_struct_fields : Map[String, Array[String]]
  enum_discriminants : Map[String, Int]
  next_offset : Int
  current_func : String?
  func_bodies : Map[String, AST]
  strings : Array[String]
  string_counter : Int
  floats : Array[Double]
  float_counter : Int
  loop_labels : Array[(String, String)]
  struct_fields : Map[String, Array[String]]
  // Buffer flags - only emit if needed
  needs_input_buf : Bool
  needs_int_buf : Bool
  needs_strcat_buf : Bool
  needs_flt_buf : Bool
  needs_arrcat_buf : Bool
  needs_map_buf : Bool
  map_buf_offset : Int
  enum_buf_offset : Int
}

///|
fn CodeGen::new() -> CodeGen {
  {
    code: [],
    labels: Map::new(),
    pending_labels: [],
    label_counter: 0,
    var_offsets: Map::new(),
    var_is_float: Map::new(),
    var_is_string: Map::new(),
    var_is_char: Map::new(),
    var_is_bool: Map::new(),
    var_is_tuple: Map::new(),
    var_is_map: Map::new(),
    var_tuple_field_types: Map::new(),
    var_array_len: Map::new(),
    var_types: Map::new(),
    var_struct_fields: Map::new(),
    enum_discriminants: Map::new(),
    next_offset: -8,
    current_func: None,
    func_bodies: Map::new(),
    strings: [],
    string_counter: 0,
    floats: [],
    float_counter: 0,
    loop_labels: [],
    struct_fields: Map::new(),
    needs_input_buf: false,
    needs_int_buf: false,
    needs_strcat_buf: false,
    needs_flt_buf: false,
    needs_arrcat_buf: false,
    needs_map_buf: false,
    map_buf_offset: 0,
    enum_buf_offset: 0,
  }
}

///|
fn CodeGen::emit_byte(self : CodeGen, b : Byte) -> CodeGen {
  { ..self, code: self.code + [b] }
}

///|
fn CodeGen::emit_bytes(self : CodeGen, bytes : Array[Byte]) -> CodeGen {
  { ..self, code: self.code + bytes }
}

///|
fn CodeGen::emit32(self : CodeGen, v : Int) -> CodeGen {
  let b0 = (v.reinterpret_as_uint() & 0xFF).to_byte()
  let b1 = ((v.reinterpret_as_uint() >> 8) & 0xFF).to_byte()
  let b2 = ((v.reinterpret_as_uint() >> 16) & 0xFF).to_byte()
  let b3 = ((v.reinterpret_as_uint() >> 24) & 0xFF).to_byte()
  let g = self.emit_byte(b0).emit_byte(b1).emit_byte(b2).emit_byte(b3)
  g
}

///|
fn CodeGen::emit64(self : CodeGen, v : Int) -> CodeGen {
  let mut g = self
  let mut i = 0
  while i < 8 {
    let b = ((v.reinterpret_as_uint() >> (i * 8)) & 0xFF).to_byte()
    g = g.emit_byte(b)
    i = i + 1
  }
  g
}

///|
fn CodeGen::new_label(self : CodeGen) -> (CodeGen, String) {
  let name = ".L\{self.label_counter}"
  ({ ..self, label_counter: self.label_counter + 1 }, name)
}

///|
fn CodeGen::define_label(self : CodeGen, name : String) -> CodeGen {
  let pos = self.code.length()
  self.labels[name] = pos
  self
}

///|
fn modrm(mod_bit : Int, reg_bit : Int, rm : Int) -> Byte {
  ((mod_bit << 6) | (reg_bit << 3) | rm).to_byte()
}

///|
fn sib(scale : Int, index : Int, base : Int) -> Byte {
  ((scale << 6) | (index << 3) | base).to_byte()
}

///|
fn xmm_reg_code(reg : String) -> Int {
  match reg {
    "xmm0" => 0
    "xmm1" => 1
    "xmm2" => 2
    "xmm3" => 3
    "xmm4" => 4
    "xmm5" => 5
    "xmm6" => 6
    "xmm7" => 7
    "xmm8" => 0
    "xmm9" => 1
    "xmm10" => 2
    "xmm11" => 3
    "xmm12" => 4
    "xmm13" => 5
    "xmm14" => 6
    "xmm15" => 7
    _ => 0
  }
}

///|
fn reg_code(reg : String) -> Int {
  match reg {
    "rax" => 0
    "rcx" => 1
    "rdx" => 2
    "rbx" => 3
    "rsp" => 4
    "rbp" => 5
    "rsi" => 6
    "rdi" => 7
    "r8" => 0
    "r9" => 1
    "r10" => 2
    "r11" => 3
    "r12" => 4
    "r13" => 5
    "r14" => 6
    "r15" => 7
    _ => 0
  }
}

///|
fn CodeGen::emit_operand64(self : CodeGen, op : X86Operand) -> CodeGen {
  match op {
    Imm8(v) => self.emit_byte(v.to_byte())
    Imm32(v) => self.emit32(v)
    Imm64(v) => self.emit64(v)
    Reg64("rax") => self.emit_byte(0xB8)
    Reg64("rcx") => self.emit_byte(0xB9)
    Reg64("rdx") => self.emit_byte(0xBA)
    Reg64("rbx") => self.emit_byte(0xBB)
    Reg64("rsp") => self.emit_byte(0xBC)
    Reg64("rbp") => self.emit_byte(0xBD)
    Reg64("rsi") => self.emit_byte(0xBE)
    Reg64("rdi") => self.emit_byte(0xBF)
    Reg64("r8") => self.emit_bytes([0x49, 0xB8])
    Reg64("r9") => self.emit_bytes([0x49, 0xB9])
    Reg64("r10") => self.emit_bytes([0x49, 0xBA])
    Reg64("r11") => self.emit_bytes([0x49, 0xBB])
    Reg64("r12") => self.emit_bytes([0x49, 0xBC])
    Reg64("r13") => self.emit_bytes([0x49, 0xBD])
    Reg64("r14") => self.emit_bytes([0x49, 0xBE])
    Reg64("r15") => self.emit_bytes([0x49, 0xBF])
    Stack64(offset) => self.emit32(offset)
    RipRel32(_label) => self.emit32(0)
    Label(name) => {
      let pos = self.code.length()
      let new_pending = self.pending_labels + [(name, pos)]
      let g = { ..self, pending_labels: new_pending }
      g.emit32(0)
    }
    _ => self
  }
}

///|
fn CodeGen::emit_modrm_reg64(
  self : CodeGen,
  reg : String,
  rm : X86Operand,
) -> CodeGen {
  let reg_code = match reg {
    "rax" => 0
    "rcx" => 1
    "rdx" => 2
    "rbx" => 3
    "rsp" => 4
    "rbp" => 5
    "rsi" => 6
    "rdi" => 7
    "r8" => 0
    "r9" => 1
    "r10" => 2
    "r11" => 3
    "r12" => 4
    "r13" => 5
    "r14" => 6
    "r15" => 7
    _ => 0
  }
  match rm {
    Reg64("rax") => self.emit_byte(modrm(3, reg_code, 0))
    Reg64("rcx") => self.emit_byte(modrm(3, reg_code, 1))
    Reg64("rdx") => self.emit_byte(modrm(3, reg_code, 2))
    Reg64("rbx") => self.emit_byte(modrm(3, reg_code, 3))
    Reg64("rsp") => self.emit_byte(modrm(3, reg_code, 4))
    Reg64("rbp") => self.emit_byte(modrm(3, reg_code, 5))
    Reg64("rsi") => self.emit_byte(modrm(3, reg_code, 6))
    Reg64("rdi") => self.emit_byte(modrm(3, reg_code, 7))
    Reg64("r8") => self.emit_byte(modrm(3, reg_code, 0))
    Reg64("r9") => self.emit_byte(modrm(3, reg_code, 1))
    Reg64("r10") => self.emit_byte(modrm(3, reg_code, 2))
    Reg64("r11") => self.emit_byte(modrm(3, reg_code, 3))
    Reg64("r12") => self.emit_byte(modrm(3, reg_code, 4))
    Reg64("r13") => self.emit_byte(modrm(3, reg_code, 5))
    Reg64("r14") => self.emit_byte(modrm(3, reg_code, 6))
    Reg64("r15") => self.emit_byte(modrm(3, reg_code, 7))
    Stack64(offset) => {
      let g = self.emit_byte(modrm(2, reg_code, 4))
      let g = g.emit_byte(sib(0, 4, 4))
      g.emit32(offset)
    }
    StackBP64(offset) => {
      // rbp-relative: mod=10, reg=reg, rm=101 (no SIB needed)
      let g = self.emit_byte(modrm(2, reg_code, 5))
      g.emit32(offset)
    }
    _ => self
  }
}

///|
fn CodeGen::_emit_rex(
  self : CodeGen,
  w : Bool,
  r : Bool,
  x : Bool,
  b : Bool,
) -> CodeGen {
  let byte = (0x40 |
  (if w { 8 } else { 0 }) |
  (if r { 4 } else { 0 }) |
  (if x { 2 } else { 0 }) |
  (if b { 1 } else { 0 })).to_byte()
  self.emit_byte(byte)
}

///|
fn CodeGen::emit_inst(self : CodeGen, inst : X86Inst) -> CodeGen {
  match inst {
    Nop => self.emit_byte(0x90)
    Ret => self.emit_byte(0xC3)
    Syscall => self.emit_bytes([0x0F, 0x05])
    RepMovsq => self.emit_bytes([0x48, 0xA5])
    Push(Reg64("rax")) => self.emit_byte(0x50)
    Push(Reg64("rcx")) => self.emit_byte(0x51)
    Push(Reg64("rdx")) => self.emit_byte(0x52)
    Push(Reg64("rbx")) => self.emit_byte(0x53)
    Push(Reg64("rsp")) => self.emit_byte(0x54)
    Push(Reg64("rbp")) => self.emit_byte(0x55)
    Push(Reg64("rsi")) => self.emit_byte(0x56)
    Push(Reg64("rdi")) => self.emit_byte(0x57)
    Push(Reg64("r8")) => self.emit_bytes([0x41, 0x50])
    Push(Reg64("r9")) => self.emit_bytes([0x41, 0x51])
    Push(Reg64("r10")) => self.emit_bytes([0x41, 0x52])
    Push(Reg64("r11")) => self.emit_bytes([0x41, 0x53])
    Push(Reg64("r12")) => self.emit_bytes([0x41, 0x54])
    Push(Reg64("r13")) => self.emit_bytes([0x41, 0x55])
    Push(Reg64("r14")) => self.emit_bytes([0x41, 0x56])
    Push(Reg64("r15")) => self.emit_bytes([0x41, 0x57])
    Push(Imm32(v)) => {
      let g = self.emit_byte(0x68)
      g.emit32(v)
    }
    Pop(Reg64("rax")) => self.emit_byte(0x58)
    Pop(Reg64("rcx")) => self.emit_byte(0x59)
    Pop(Reg64("rdx")) => self.emit_byte(0x5A)
    Pop(Reg64("rbx")) => self.emit_byte(0x5B)
    Pop(Reg64("rsp")) => self.emit_byte(0x5C)
    Pop(Reg64("rbp")) => self.emit_byte(0x5D)
    Pop(Reg64("rsi")) => self.emit_byte(0x5E)
    Pop(Reg64("rdi")) => self.emit_byte(0x5F)
    Pop(Reg64("r8")) => self.emit_bytes([0x41, 0x58])
    Pop(Reg64("r9")) => self.emit_bytes([0x41, 0x59])
    Pop(Reg64("r10")) => self.emit_bytes([0x41, 0x5A])
    Pop(Reg64("r11")) => self.emit_bytes([0x41, 0x5B])
    Pop(Reg64("r12")) => self.emit_bytes([0x41, 0x5C])
    Pop(Reg64("r13")) => self.emit_bytes([0x41, 0x5D])
    Pop(Reg64("r14")) => self.emit_bytes([0x41, 0x5E])
    Pop(Reg64("r15")) => self.emit_bytes([0x41, 0x5F])
    Mov(Reg64(dest), Imm32(v)) =>
      match dest {
        "r8" | "r9" | "r10" | "r11" | "r12" | "r13" | "r14" | "r15" => {
          let reg_code = match dest {
            "r8" => 0
            "r9" => 1
            "r10" => 2
            "r11" => 3
            "r12" => 4
            "r13" => 5
            "r14" => 6
            "r15" => 7
            _ => 0
          }
          let g = self.emit_byte(0x49)
          let g = g.emit_byte(0xC7)
          let g = g.emit_byte(modrm(3, 0, reg_code))
          g.emit32(v)
        }
        _ => {
          let g = self.emit_operand64(Reg64(dest))
          g.emit32(v)
        }
      }
    Mov(Reg64(dest), Imm64(v)) => {
      let g = self.emit_operand64(Reg64(dest))
      g.emit64(v)
    }
    Mov(Reg64(dest), Reg64(src)) => {
      let src_code = match src {
        "rax" => 0
        "rcx" => 1
        "rdx" => 2
        "rbx" => 3
        "rsp" => 4
        "rbp" => 5
        "rsi" => 6
        "rdi" => 7
        "r8" => 0
        "r9" => 1
        "r10" => 2
        "r11" => 3
        "r12" => 4
        "r13" => 5
        "r14" => 6
        "r15" => 7
        _ => 0
      }
      let dest_code = match dest {
        "rax" => 0
        "rcx" => 1
        "rdx" => 2
        "rbx" => 3
        "rsp" => 4
        "rbp" => 5
        "rsi" => 6
        "rdi" => 7
        "r8" => 0
        "r9" => 1
        "r10" => 2
        "r11" => 3
        "r12" => 4
        "r13" => 5
        "r14" => 6
        "r15" => 7
        _ => 0
      }
      let src_ext = src == "r8" ||
        src == "r9" ||
        src == "r10" ||
        src == "r11" ||
        src == "r12" ||
        src == "r13" ||
        src == "r14" ||
        src == "r15"
      let dest_ext = dest == "r8" ||
        dest == "r9" ||
        dest == "r10" ||
        dest == "r11" ||
        dest == "r12" ||
        dest == "r13" ||
        dest == "r14" ||
        dest == "r15"
      let g = self._emit_rex(true, src_ext, false, dest_ext)
      let g = g.emit_byte(0x89)
      g.emit_byte(modrm(3, src_code, dest_code))
    }
    Mov(Reg64(dest), Stack64(offset)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x8B)
      let g = g.emit_modrm_reg64(dest, Stack64(offset))
      g
    }
    Mov(Reg64(dest), StackBP64(offset)) => {
      let dest_ext = dest == "r8" ||
        dest == "r9" ||
        dest == "r10" ||
        dest == "r11" ||
        dest == "r12" ||
        dest == "r13" ||
        dest == "r14" ||
        dest == "r15"
      let g = if dest_ext {
        self.emit_bytes([0x4C, 0x8B])
      } else {
        self.emit_bytes([0x48, 0x8B])
      }
      g.emit_modrm_reg64(dest, StackBP64(offset))
    }
    Mov(Stack64(offset), Reg64(src)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x89)
      let g = g.emit_modrm_reg64(src, Stack64(offset))
      g
    }
    Mov(StackBP64(offset), Reg64(src)) => {
      // mov [rbp+offset], reg64
      let g = self.emit_byte(0x48) // REX.w
      let g = g.emit_byte(0x89) // ModR/M for mov r/m64, reg64
      let g = g.emit_modrm_reg64(src, StackBP64(offset))
      g
    }
    Mov(Reg64(dest), MemOffset(addr_reg, offset)) => {
      let dest_ext = dest == "r8" ||
        dest == "r9" ||
        dest == "r10" ||
        dest == "r11" ||
        dest == "r12" ||
        dest == "r13" ||
        dest == "r14" ||
        dest == "r15"
      let dest_code = match dest {
        "rax" => 0
        "rcx" => 1
        "rdx" => 2
        "rbx" => 3
        "rsp" => 4
        "rbp" => 5
        "rsi" => 6
        "rdi" => 7
        "r8" => 0
        "r9" => 1
        "r10" => 2
        "r11" => 3
        "r12" => 4
        "r13" => 5
        "r14" => 6
        "r15" => 7
        _ => 0
      }
      let rm_code = match addr_reg {
        "rax" => 0
        "rcx" => 1
        "rdx" => 2
        "rbx" => 3
        "rsp" => 4
        "rbp" => 5
        "rsi" => 6
        "rdi" => 7
        _ => 0
      }
      let mut g = if dest_ext {
        self.emit_byte(0x4C)
      } else {
        self.emit_byte(0x48)
      }
      g = g.emit_byte(0x8B)
      if addr_reg == "rsp" {
        g = g.emit_byte(modrm(2, dest_code, 4))
        g = g.emit_byte(sib(0, 4, 4))
        g = g.emit32(offset)
      } else if addr_reg == "rbp" {
        g = g.emit_byte(modrm(2, dest_code, 5))
        g = g.emit32(offset)
      } else if offset >= -128 && offset <= 127 {
        g = g.emit_byte(modrm(1, dest_code, rm_code))
        g = g.emit_byte(offset.to_byte())
      } else {
        g = g.emit_byte(modrm(2, dest_code, rm_code))
        g = g.emit32(offset)
      }
      g
    }
    Mov(Reg64(dest), MemIndirect(addr_reg)) => {
      let dest_ext = dest == "r8" ||
        dest == "r9" ||
        dest == "r10" ||
        dest == "r11" ||
        dest == "r12" ||
        dest == "r13" ||
        dest == "r14" ||
        dest == "r15"
      let dest_code = match dest {
        "rax" => 0
        "rcx" => 1
        "rdx" => 2
        "rbx" => 3
        "rsp" => 4
        "rbp" => 5
        "rsi" => 6
        "rdi" => 7
        "r8" => 0
        "r9" => 1
        "r10" => 2
        "r11" => 3
        "r12" => 4
        "r13" => 5
        "r14" => 6
        "r15" => 7
        _ => 0
      }
      let rm_code = match addr_reg {
        "rax" => 0
        "rcx" => 1
        "rdx" => 2
        "rbx" => 3
        "rsp" => 4
        "rbp" => 5
        "rsi" => 6
        "rdi" => 7
        _ => 0
      }
      let g = if dest_ext { self.emit_byte(0x4C) } else { self.emit_byte(0x48) }
      let g = g.emit_byte(0x8B)
      if addr_reg == "rsp" {
        let g = g.emit_byte(modrm(0, dest_code, 4))
        g.emit_byte(sib(0, 4, 4))
      } else if addr_reg == "rbp" {
        let g = g.emit_byte(modrm(1, dest_code, 5))
        g.emit_byte(0x00)
      } else {
        g.emit_byte(modrm(0, dest_code, rm_code))
      }
    }
    Mov(MemIndirect(addr_reg), Reg64(src)) => {
      // mov [addr_reg], reg64
      let src_code = match src {
        "rax" => 0
        "rcx" => 1
        "rdx" => 2
        "rbx" => 3
        "rsp" => 4
        "rbp" => 5
        "rsi" => 6
        "rdi" => 7
        _ => 0
      }
      let rm_code = match addr_reg {
        "rax" => 0
        "rcx" => 1
        "rdx" => 2
        "rbx" => 3
        "rsp" => 4
        "rbp" => 5
        "rsi" => 6
        "rdi" => 7
        _ => 0
      }
      // REX.W + 89 + ModRM (mod=00, reg=src, rm=addr_reg)
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x89)
      if addr_reg == "rsp" {
        let g = g.emit_byte(modrm(0, src_code, 4))
        g.emit_byte(sib(0, 4, 4))
      } else if addr_reg == "rbp" {
        let g = g.emit_byte(modrm(1, src_code, 5))
        g.emit_byte(0x00)
      } else {
        g.emit_byte(modrm(0, src_code, rm_code))
      }
    }
    Mov(MemIndirect(addr_reg), Reg8(src)) => {
      let reg_code = match src {
        "al" => 0
        "cl" => 1
        "dl" => 2
        "bl" => 3
        "sil" => 6
        "dil" => 7
        "r8b" => 0
        "r9b" => 1
        "r10b" => 2
        "r11b" => 3
        "r12b" => 4
        "r13b" => 5
        "r14b" => 6
        "r15b" => 7
        _ => 0
      }
      let rm_code = match addr_reg {
        "rax" => 0
        "rcx" => 1
        "rdx" => 2
        "rbx" => 3
        "rsp" => 4
        "rbp" => 5
        "rsi" => 6
        "rdi" => 7
        _ => 0
      }
      let needs_rex = src == "r8b" ||
        src == "r9b" ||
        src == "r10b" ||
        src == "r11b" ||
        src == "r12b" ||
        src == "r13b" ||
        src == "r14b" ||
        src == "r15b" ||
        src == "sil" ||
        src == "dil"
      let mut g = self
      if needs_rex {
        g = g.emit_byte(0x40)
      }
      g = g.emit_byte(0x88)
      if addr_reg == "rsp" {
        g = g.emit_byte(modrm(0, reg_code, 4))
        g.emit_byte(sib(0, 4, 4))
      } else if addr_reg == "rbp" {
        g = g.emit_byte(modrm(1, reg_code, 5))
        g.emit_byte(0x00)
      } else {
        g.emit_byte(modrm(0, reg_code, rm_code))
      }
    }
    Mov(MemIndirect(addr_reg), Imm8(v)) => {
      let rm_code = match addr_reg {
        "rax" => 0
        "rcx" => 1
        "rdx" => 2
        "rbx" => 3
        "rsp" => 4
        "rbp" => 5
        "rsi" => 6
        "rdi" => 7
        _ => 0
      }
      let mut g = self.emit_byte(0xC6)
      if addr_reg == "rsp" {
        g = g.emit_byte(modrm(0, 0, 4))
        g = g.emit_byte(sib(0, 4, 4))
      } else if addr_reg == "rbp" {
        g = g.emit_byte(modrm(1, 0, 5))
        g = g.emit_byte(0x00)
      } else {
        g = g.emit_byte(modrm(0, 0, rm_code))
      }
      g.emit_byte(v.to_byte())
    }
    Mov(MemOffset(addr_reg, offset), Imm32(v)) => {
      let rm_code = match addr_reg {
        "rax" => 0
        "rcx" => 1
        "rdx" => 2
        "rbx" => 3
        "rsp" => 4
        "rbp" => 5
        "rsi" => 6
        "rdi" => 7
        _ => 0
      }
      let mut g = self.emit_byte(0x48) // REX.W
      if addr_reg == "rsp" {
        g = g.emit_byte(0xC7)
        g = g.emit_byte(modrm(2, 0, 4))
        g = g.emit_byte(sib(0, 4, 4))
        g = g.emit32(offset)
      } else if addr_reg == "rbp" {
        g = g.emit_byte(0xC7)
        g = g.emit_byte(modrm(2, 0, 5))
        g = g.emit32(offset)
      } else if offset >= -128 && offset <= 127 {
        g = g.emit_byte(0xC7)
        g = g.emit_byte(modrm(1, 0, rm_code))
        g = g.emit_byte(offset.to_byte())
      } else {
        g = g.emit_byte(0xC7)
        g = g.emit_byte(modrm(2, 0, rm_code))
        g = g.emit32(offset)
      }
      g.emit32(v)
    }
    Mov(MemOffset(addr_reg, offset), Reg64(src)) => {
      let reg_code = match src {
        "rax" => 0
        "rcx" => 1
        "rdx" => 2
        "rbx" => 3
        "rsp" => 4
        "rbp" => 5
        "rsi" => 6
        "rdi" => 7
        _ => 0
      }
      let rm_code = match addr_reg {
        "rax" => 0
        "rcx" => 1
        "rdx" => 2
        "rbx" => 3
        "rsp" => 4
        "rbp" => 5
        "rsi" => 6
        "rdi" => 7
        _ => 0
      }
      let mut g = self.emit_byte(0x48) // REX.W
      if addr_reg == "rsp" {
        g = g.emit_byte(0x89)
        g = g.emit_byte(modrm(2, reg_code, 4))
        g = g.emit_byte(sib(0, 4, 4))
        g = g.emit32(offset)
      } else if addr_reg == "rbp" {
        g = g.emit_byte(0x89)
        g = g.emit_byte(modrm(2, reg_code, 5))
        g = g.emit32(offset)
      } else if offset >= -128 && offset <= 127 {
        g = g.emit_byte(0x89)
        g = g.emit_byte(modrm(1, reg_code, rm_code))
        g = g.emit_byte(offset.to_byte())
      } else {
        g = g.emit_byte(0x89)
        g = g.emit_byte(modrm(2, reg_code, rm_code))
        g = g.emit32(offset)
      }
      g
    }
    Mov(Reg8(dest), Reg8(src)) => {
      let src_code = match src {
        "al" => 0
        "cl" => 1
        "dl" => 2
        "bl" => 3
        "sil" => 6
        "dil" => 7
        _ => 0
      }
      let dest_code = match dest {
        "al" => 0
        "cl" => 1
        "dl" => 2
        "bl" => 3
        "sil" => 6
        "dil" => 7
        _ => 0
      }
      let needs_rex = src == "sil" ||
        src == "dil" ||
        dest == "sil" ||
        dest == "dil"
      let mut g = self
      if needs_rex {
        g = g.emit_byte(0x40)
      }
      g = g.emit_byte(0x88)
      g.emit_byte(modrm(3, src_code, dest_code))
    }
    Mov(Reg8(dest), Imm8(v)) => {
      let dest_code = match dest {
        "al" => 0
        "cl" => 1
        "dl" => 2
        "bl" => 3
        "sil" => 6
        "dil" => 7
        _ => 0
      }
      let needs_rex = dest == "sil" || dest == "dil"
      let mut g = self
      if needs_rex {
        g = g.emit_byte(0x40)
      }
      g = g.emit_byte((0xB0 + dest_code).to_byte())
      g.emit_byte(v.to_byte())
    }
    Movzx(Reg64(dest), Reg8(src)) => {
      let dest_code = match dest {
        "rax" => 0
        "rcx" => 1
        "rdx" => 2
        "rbx" => 3
        "rsp" => 4
        "rbp" => 5
        "rsi" => 6
        "rdi" => 7
        _ => 0
      }
      let src_code = match src {
        "al" => 0
        "cl" => 1
        "dl" => 2
        "bl" => 3
        "sil" => 6
        "dil" => 7
        _ => 0
      }
      let needs_rex = src == "sil" || src == "dil"
      let mut g = self
      if needs_rex {
        g = g.emit_byte(0x40)
      }
      g = g.emit_byte(0x0F)
      g = g.emit_byte(0xB6)
      g.emit_byte(modrm(3, dest_code, src_code))
    }
    Movzx(Reg64(dest), MemIndirect(addr_reg)) => {
      let dest_code = match dest {
        "rax" => 0
        "rcx" => 1
        "rdx" => 2
        "rbx" => 3
        "rsp" => 4
        "rbp" => 5
        "rsi" => 6
        "rdi" => 7
        _ => 0
      }
      let rm_code = match addr_reg {
        "rax" => 0
        "rcx" => 1
        "rdx" => 2
        "rbx" => 3
        "rsp" => 4
        "rbp" => 5
        "rsi" => 6
        "rdi" => 7
        _ => 0
      }
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x0F)
      let g = g.emit_byte(0xB6)
      if addr_reg == "rsp" {
        let g = g.emit_byte(modrm(0, dest_code, 4))
        g.emit_byte(sib(0, 4, 4))
      } else if addr_reg == "rbp" {
        let g = g.emit_byte(modrm(1, dest_code, 5))
        g.emit_byte(0x00)
      } else {
        g.emit_byte(modrm(0, dest_code, rm_code))
      }
    }
    Lea(Reg64(dest), RipRel32(label)) => {
      let reg_code = match dest {
        "rax" => 0
        "rcx" => 1
        "rdx" => 2
        "rbx" => 3
        "rsp" => 4
        "rbp" => 5
        "rsi" => 6
        "rdi" => 7
        "r8" => 0
        "r9" => 1
        "r10" => 2
        "r11" => 3
        "r12" => 4
        "r13" => 5
        "r14" => 6
        "r15" => 7
        _ => 0
      }
      let g = self.emit_byte(0x48) // REX.w
      let g = g.emit_byte(0x8D) // LEA
      let g = g.emit_byte(modrm(0, reg_code, 5)) // mod=00, reg=reg, rm=101 (RIP)
      let pos = g.code.length()
      let new_pending = g.pending_labels + [(label, pos)]
      let g = { ..g, pending_labels: new_pending }
      g.emit32(0)
    }
    Add(Reg64(dest), Reg64(src)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x01)
      let g = g.emit_modrm_reg64(src, Reg64(dest))
      g
    }
    Add(Reg64(dest), Imm32(v)) => {
      let rm_code = match dest {
        "rax" => 0
        "rcx" => 1
        "rdx" => 2
        "rbx" => 3
        "rsp" => 4
        "rbp" => 5
        "rsi" => 6
        "rdi" => 7
        _ => 0
      }
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x81)
      let g = g.emit_byte(modrm(3, 0, rm_code))
      g.emit32(v)
    }
    Sub(Reg64(dest), Reg64(src)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x29)
      let g = g.emit_modrm_reg64(src, Reg64(dest))
      g
    }
    Sub(Reg64(dest), Imm32(v)) => {
      let rm_code = match dest {
        "rax" => 0
        "rcx" => 1
        "rdx" => 2
        "rbx" => 3
        "rsp" => 4
        "rbp" => 5
        "rsi" => 6
        "rdi" => 7
        _ => 0
      }
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x81)
      let g = g.emit_byte(modrm(3, 5, rm_code))
      g.emit32(v)
    }
    Imul(Reg64(dest), Reg64(src)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x0F)
      let g = g.emit_byte(0xAF)
      // IMUL r64, r/m64: dest in reg field, src in r/m field
      let g = g.emit_modrm_reg64(dest, Reg64(src))
      g
    }
    Idiv(Reg64(src)) => {
      let src_code = match src {
        "rax" => 0
        "rcx" => 1
        "rdx" => 2
        "rbx" => 3
        "rsp" => 4
        "rbp" => 5
        "rsi" => 6
        "rdi" => 7
        "r8" => 0
        "r9" => 1
        "r10" => 2
        "r11" => 3
        "r12" => 4
        "r13" => 5
        "r14" => 6
        "r15" => 7
        _ => 0
      }
      let is_ext = src == "r8" ||
        src == "r9" ||
        src == "r10" ||
        src == "r11" ||
        src == "r12" ||
        src == "r13" ||
        src == "r14" ||
        src == "r15"
      let rex : Byte = if is_ext { 0x49 } else { 0x48 }
      let g = self.emit_byte(rex)
      let g = g.emit_byte(0xF7)
      let g = g.emit_byte(modrm(3, 7, src_code))
      g
    }
    Cmp(Reg64(dest), Reg64(src)) => {
      let src_ext = src == "r8" ||
        src == "r9" ||
        src == "r10" ||
        src == "r11" ||
        src == "r12" ||
        src == "r13" ||
        src == "r14" ||
        src == "r15"
      let dest_ext = dest == "r8" ||
        dest == "r9" ||
        dest == "r10" ||
        dest == "r11" ||
        dest == "r12" ||
        dest == "r13" ||
        dest == "r14" ||
        dest == "r15"
      let rex_value = (0x40 |
      (if src_ext { 4 } else { 0 }) |
      (if dest_ext { 1 } else { 0 })).to_byte()
      let g = self.emit_byte(rex_value)
      let g = g.emit_byte(0x39)
      let g = g.emit_modrm_reg64(src, Reg64(dest))
      g
    }
    Cmp(Reg64(dest), Imm32(v)) => {
      let (rm_code, rex_b) = match dest {
        "rax" => (0, false)
        "rcx" => (1, false)
        "rdx" => (2, false)
        "rbx" => (3, false)
        "rsp" => (4, false)
        "rbp" => (5, false)
        "rsi" => (6, false)
        "rdi" => (7, false)
        "r8" => (0, true)
        "r9" => (1, true)
        "r10" => (2, true)
        "r11" => (3, true)
        "r12" => (4, true)
        "r13" => (5, true)
        "r14" => (6, true)
        "r15" => (7, true)
        _ => (0, false)
      }
      let g = if rex_b { self.emit_byte(0x49) } else { self.emit_byte(0x48) }
      let g = g.emit_byte(0x81)
      let g = g.emit_byte(modrm(3, 7, rm_code))
      g.emit32(v)
    }
    Test(Reg64(dest), Reg64(src)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x85)
      let g = g.emit_modrm_reg64(src, Reg64(dest))
      g
    }
    And(Reg64(dest), Reg64(src)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x21)
      let g = g.emit_modrm_reg64(src, Reg64(dest))
      g
    }
    And(Reg64(dest), Imm32(v)) => {
      let rm_code = match dest {
        "rax" => 0
        "rcx" => 1
        "rdx" => 2
        "rbx" => 3
        "rsp" => 4
        "rbp" => 5
        "rsi" => 6
        "rdi" => 7
        _ => 0
      }
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x81)
      let g = g.emit_byte(modrm(3, 4, rm_code))
      g.emit32(v)
    }
    Or(Reg64(dest), Reg64(src)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x09)
      let g = g.emit_modrm_reg64(src, Reg64(dest))
      g
    }
    Or(Reg64(dest), Imm32(v)) => {
      let rm_code = match dest {
        "rax" => 0
        "rcx" => 1
        "rdx" => 2
        "rbx" => 3
        "rsp" => 4
        "rbp" => 5
        "rsi" => 6
        "rdi" => 7
        _ => 0
      }
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x81)
      let g = g.emit_byte(modrm(3, 1, rm_code))
      g.emit32(v)
    }
    Xor(Reg64(dest), Reg64(src)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x31)
      let g = g.emit_modrm_reg64(src, Reg64(dest))
      g
    }
    Xor(Reg64(dest), Imm32(v)) => {
      let rm_code = match dest {
        "rax" => 0
        "rcx" => 1
        "rdx" => 2
        "rbx" => 3
        "rsp" => 4
        "rbp" => 5
        "rsi" => 6
        "rdi" => 7
        _ => 0
      }
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x81)
      let g = g.emit_byte(modrm(3, 6, rm_code))
      g.emit32(v)
    }
    Not(Reg64(dest)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0xF7)
      let g = g.emit_modrm_reg64("rdx", Reg64(dest))
      g
    }
    Neg(Reg64(dest)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0xF7)
      let g = g.emit_modrm_reg64("rbx", Reg64(dest))
      g
    }
    Inc(Reg64(dest)) =>
      match dest {
        "r8" | "r9" | "r10" | "r11" | "r12" | "r13" | "r14" | "r15" => {
          let rm_code = match dest {
            "r8" => 0
            "r9" => 1
            "r10" => 2
            "r11" => 3
            "r12" => 4
            "r13" => 5
            "r14" => 6
            "r15" => 7
            _ => 0
          }
          let g = self.emit_byte(0x49)
          let g = g.emit_byte(0xFF)
          g.emit_byte(modrm(3, 0, rm_code))
        }
        _ => {
          let g = self.emit_byte(0x48)
          let g = g.emit_byte(0xFF)
          let g = g.emit_modrm_reg64("rax", Reg64(dest))
          g
        }
      }
    Dec(Reg64(dest)) =>
      match dest {
        "r8" | "r9" | "r10" | "r11" | "r12" | "r13" | "r14" | "r15" => {
          let rm_code = match dest {
            "r8" => 0
            "r9" => 1
            "r10" => 2
            "r11" => 3
            "r12" => 4
            "r13" => 5
            "r14" => 6
            "r15" => 7
            _ => 0
          }
          let g = self.emit_byte(0x49)
          let g = g.emit_byte(0xFF)
          g.emit_byte(modrm(3, 1, rm_code))
        }
        _ => {
          let g = self.emit_byte(0x48)
          let g = g.emit_byte(0xFF)
          let g = g.emit_modrm_reg64("rcx", Reg64(dest))
          g
        }
      }
    Cqo => {
      // cqo - sign-extend rax into rdx:rax
      // REX.W = 01001000 = 0x48
      // opcode = 0x99
      let g = self.emit_byte(0x48)
      g.emit_byte(0x99)
    }
    Shl(Reg64(dest), Imm8(1)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0xD1)
      let g = g.emit_modrm_reg64("rcx", Reg64(dest))
      g
    }
    Shl(Reg64(dest), Imm8(v)) => {
      // SHL r/m64, imm8 = REX.W + C1 /4 ib
      let dest_code = match dest {
        "rax" => 0
        "rcx" => 1
        "rdx" => 2
        "rbx" => 3
        "rsp" => 4
        "rbp" => 5
        "rsi" => 6
        "rdi" => 7
        "r8" => 0
        "r9" => 1
        "r10" => 2
        "r11" => 3
        "r12" => 4
        "r13" => 5
        "r14" => 6
        "r15" => 7
        _ => 0
      }
      let dest_ext = dest == "r8" ||
        dest == "r9" ||
        dest == "r10" ||
        dest == "r11" ||
        dest == "r12" ||
        dest == "r13" ||
        dest == "r14" ||
        dest == "r15"
      let rex = if dest_ext { 0x49 } else { 0x48 }
      let g = self.emit_bytes([rex.to_byte(), 0xC1])
      let g = g.emit_byte(modrm(3, 4, dest_code)) // /4 = SHL
      g.emit_byte(v.to_byte())
    }
    Shr(Reg64(dest), Imm8(1)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0xD1)
      let g = g.emit_modrm_reg64("rcx", Reg64(dest))
      g
    }
    Shr(Reg64(dest), Imm32(v)) => {
      // shr rdest, v
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0xC1)
      let g = g.emit_modrm_reg64("rcx", Reg64(dest))
      g.emit_byte(v.to_byte())
    }
    Sar(Reg64(dest), Imm8(1)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0xD1)
      let g = g.emit_modrm_reg64("rcx", Reg64(dest))
      g
    }
    // Variable shift by cl register
    Shl(Reg64(dest), Reg64("cl")) => {
      // shl r64, cl = REX.W + D3 /4
      let rm_code = match dest {
        "rax" => 0
        "rcx" => 1
        "rdx" => 2
        "rbx" => 3
        "rsp" => 4
        "rbp" => 5
        "rsi" => 6
        "rdi" => 7
        _ => 0
      }
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0xD3)
      g.emit_byte(modrm(3, 4, rm_code))
    }
    Shr(Reg64(dest), Reg64("cl")) => {
      // shr r64, cl = REX.W + D3 /5
      let rm_code = match dest {
        "rax" => 0
        "rcx" => 1
        "rdx" => 2
        "rbx" => 3
        "rsp" => 4
        "rbp" => 5
        "rsi" => 6
        "rdi" => 7
        _ => 0
      }
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0xD3)
      g.emit_byte(modrm(3, 5, rm_code))
    }
    Sar(Reg64(dest), Reg64("cl")) => {
      // sar r64, cl = REX.W + D3 /7
      let rm_code = match dest {
        "rax" => 0
        "rcx" => 1
        "rdx" => 2
        "rbx" => 3
        "rsp" => 4
        "rbp" => 5
        "rsi" => 6
        "rdi" => 7
        _ => 0
      }
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0xD3)
      g.emit_byte(modrm(3, 7, rm_code))
    }
    Jmp(label) => {
      let g = self.emit_byte(0xE9)
      let pos = g.code.length()
      let new_pending = g.pending_labels + [(label, pos)]
      let g = { ..g, pending_labels: new_pending }
      g.emit32(0)
    }
    Je(label) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x84)
      let pos = g.code.length()
      let new_pending = g.pending_labels + [(label, pos)]
      let g = { ..g, pending_labels: new_pending }
      g.emit32(0)
    }
    Jne(label) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x85)
      let pos = g.code.length()
      let new_pending = g.pending_labels + [(label, pos)]
      let g = { ..g, pending_labels: new_pending }
      g.emit32(0)
    }
    Jg(label) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x8F)
      let pos = g.code.length()
      let new_pending = g.pending_labels + [(label, pos)]
      let g = { ..g, pending_labels: new_pending }
      g.emit32(0)
    }
    Jge(label) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x8D)
      let pos = g.code.length()
      let new_pending = g.pending_labels + [(label, pos)]
      let g = { ..g, pending_labels: new_pending }
      g.emit32(0)
    }
    Jl(label) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x8C)
      let pos = g.code.length()
      let new_pending = g.pending_labels + [(label, pos)]
      let g = { ..g, pending_labels: new_pending }
      g.emit32(0)
    }
    Jle(label) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x8E)
      let pos = g.code.length()
      let new_pending = g.pending_labels + [(label, pos)]
      let g = { ..g, pending_labels: new_pending }
      g.emit32(0)
    }
    Ja(label) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x87)
      let pos = g.code.length()
      let new_pending = g.pending_labels + [(label, pos)]
      let g = { ..g, pending_labels: new_pending }
      g.emit32(0)
    }
    Jae(label) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x83)
      let pos = g.code.length()
      let new_pending = g.pending_labels + [(label, pos)]
      let g = { ..g, pending_labels: new_pending }
      g.emit32(0)
    }
    Jb(label) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x82)
      let pos = g.code.length()
      let new_pending = g.pending_labels + [(label, pos)]
      let g = { ..g, pending_labels: new_pending }
      g.emit32(0)
    }
    Jbe(label) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x86)
      let pos = g.code.length()
      let new_pending = g.pending_labels + [(label, pos)]
      let g = { ..g, pending_labels: new_pending }
      g.emit32(0)
    }
    Jz(label) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x84)
      let pos = g.code.length()
      let new_pending = g.pending_labels + [(label, pos)]
      let g = { ..g, pending_labels: new_pending }
      g.emit32(0)
    }
    Jnz(label) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x85)
      let pos = g.code.length()
      let new_pending = g.pending_labels + [(label, pos)]
      let g = { ..g, pending_labels: new_pending }
      g.emit32(0)
    }
    Jp(label) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x8A)
      let pos = g.code.length()
      let new_pending = g.pending_labels + [(label, pos)]
      let g = { ..g, pending_labels: new_pending }
      g.emit32(0)
    }
    Setz(_dest) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x94)
      let g = g.emit_byte(modrm(3, 0, 0))
      g
    }
    Setnz(_dest) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x95)
      let g = g.emit_byte(modrm(3, 0, 0))
      g
    }
    Setg(_dest) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x9F)
      let g = g.emit_byte(modrm(3, 0, 0))
      g
    }
    Setge(_dest) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x9D)
      let g = g.emit_byte(modrm(3, 0, 0))
      g
    }
    Setl(_dest) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x9C)
      let g = g.emit_byte(modrm(3, 0, 0))
      g
    }
    Setle(_dest) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x9E)
      let g = g.emit_byte(modrm(3, 0, 0))
      g
    }
    Seta(_dest) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x97)
      let g = g.emit_byte(modrm(3, 0, 0))
      g
    }
    Setae(_dest) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x93)
      let g = g.emit_byte(modrm(3, 0, 0))
      g
    }
    Setb(_dest) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x92)
      let g = g.emit_byte(modrm(3, 0, 0))
      g
    }
    Setbe(_dest) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x96)
      let g = g.emit_byte(modrm(3, 0, 0))
      g
    }
    PushXmm(reg) => {
      let reg_code = xmm_reg_code(reg)
      let g = self.emit_bytes([0x48, 0x83, 0xEC, 0x08])
      let g = g.emit_bytes([0xF2, 0x0F, 0x11])
      let g = g.emit_byte(modrm(0, reg_code, 4))
      g.emit_byte(sib(0, 4, 4))
    }
    PopXmm(reg) => {
      let reg_code = xmm_reg_code(reg)
      let g = self.emit_bytes([0xF2, 0x0F, 0x10])
      let g = g.emit_byte(modrm(0, reg_code, 4))
      let g = g.emit_byte(sib(0, 4, 4))
      g.emit_bytes([0x48, 0x83, 0xC4, 0x08])
    }
    Call(label) => {
      let g = self.emit_byte(0xE8)
      let pos = g.code.length()
      let new_pending = g.pending_labels + [(label, pos)]
      let g = { ..g, pending_labels: new_pending }
      g.emit32(0)
    }
    Movsd(Xmm(dest), Xmm(src)) => {
      let g = self.emit_bytes([0xF2, 0x0F, 0x10])
      let dest_code = xmm_reg_code(dest)
      let src_code = xmm_reg_code(src)
      g.emit_byte(modrm(3, src_code, dest_code))
    }
    Movsd(Xmm(dest), RipRel32(label)) => {
      let g = self.emit_bytes([0xF2, 0x0F, 0x10])
      let dest_code = xmm_reg_code(dest)
      let g = g.emit_byte(modrm(0, dest_code, 5))
      let pos = g.code.length()
      let new_pending = g.pending_labels + [(label, pos)]
      let g = { ..g, pending_labels: new_pending }
      g.emit32(0)
    }
    Movsd(RipRel32(label), Xmm(src)) => {
      let g = self.emit_bytes([0xF2, 0x0F, 0x11])
      let src_code = xmm_reg_code(src)
      let g = g.emit_byte(modrm(0, src_code, 5))
      let pos = g.code.length()
      let new_pending = g.pending_labels + [(label, pos)]
      let g = { ..g, pending_labels: new_pending }
      g.emit32(0)
    }
    Movsd(Xmm(dest), StackBP64(offset)) => {
      let dest_code = xmm_reg_code(dest)
      let g = self.emit_bytes([0xF2, 0x0F, 0x10])
      let g = g.emit_byte(modrm(2, dest_code, 5))
      g.emit32(offset)
    }
    Movsd(Xmm(dest), MemIndirect(base)) => {
      let dest_code = xmm_reg_code(dest)
      let base_code = reg_code(base)
      let g = self.emit_bytes([0xF2, 0x0F, 0x10])
      if base == "rsp" {
        let g = g.emit_byte(modrm(0, dest_code, 4))
        g.emit_byte(sib(0, 4, 4))
      } else {
        g.emit_byte(modrm(0, dest_code, base_code))
      }
    }
    Movsd(StackBP64(offset), Xmm(src)) => {
      let src_code = xmm_reg_code(src)
      let g = self.emit_bytes([0xF2, 0x0F, 0x11])
      let g = g.emit_byte(modrm(2, src_code, 5))
      g.emit32(offset)
    }
    Movsd(MemIndirect(base), Xmm(src)) => {
      let src_code = xmm_reg_code(src)
      let base_code = reg_code(base)
      let g = self.emit_bytes([0xF2, 0x0F, 0x11])
      if base == "rsp" {
        let g = g.emit_byte(modrm(0, src_code, 4))
        g.emit_byte(sib(0, 4, 4))
      } else {
        g.emit_byte(modrm(0, src_code, base_code))
      }
    }
    Addsd(Xmm(dest), Xmm(src)) => {
      let g = self.emit_bytes([0xF2, 0x0F, 0x58])
      let dest_code = xmm_reg_code(dest)
      let src_code = xmm_reg_code(src)
      g.emit_byte(modrm(3, dest_code, src_code))
    }
    Subsd(Xmm(dest), Xmm(src)) => {
      let g = self.emit_bytes([0xF2, 0x0F, 0x5C])
      let dest_code = xmm_reg_code(dest)
      let src_code = xmm_reg_code(src)
      g.emit_byte(modrm(3, dest_code, src_code))
    }
    Mulsd(Xmm(dest), Xmm(src)) => {
      let g = self.emit_bytes([0xF2, 0x0F, 0x59])
      let dest_code = xmm_reg_code(dest)
      let src_code = xmm_reg_code(src)
      g.emit_byte(modrm(3, dest_code, src_code))
    }
    Divsd(Xmm(dest), Xmm(src)) => {
      let g = self.emit_bytes([0xF2, 0x0F, 0x5E])
      let dest_code = xmm_reg_code(dest)
      let src_code = xmm_reg_code(src)
      g.emit_byte(modrm(3, dest_code, src_code))
    }
    Ucomisd(Xmm(dest), Xmm(src)) => {
      let g = self.emit_bytes([0x66, 0x0F, 0x2E])
      let dest_code = xmm_reg_code(dest)
      let src_code = xmm_reg_code(src)
      g.emit_byte(modrm(3, dest_code, src_code))
    }
    Cvtsi2sd(Xmm(dest), Reg64(src)) => {
      let g = self.emit_bytes([0xF2, 0x48, 0x0F, 0x2A])
      let dest_code = xmm_reg_code(dest)
      let src_code = reg_code(src)
      g.emit_byte(modrm(3, dest_code, src_code))
    }
    Cvttsd2si(Reg64(dest), Xmm(src)) => {
      let g = self.emit_bytes([0xF2, 0x48, 0x0F, 0x2C])
      let dest_code = reg_code(dest)
      let src_code = xmm_reg_code(src)
      g.emit_byte(modrm(3, src_code, dest_code))
    }
    _ => self
  }
}

///|
fn CodeGen::add_string(self : CodeGen, s : String) -> (CodeGen, String) {
  // Check if string already exists (for deduplication)
  let mut idx = 0
  let mut found_idx = -1
  while idx < self.strings.length() {
    if self.strings[idx] == s {
      found_idx = idx
      idx = self.strings.length()
    }
    idx = idx + 1
  }
  if found_idx >= 0 {
    // Reuse existing string
    let label = ".Lstr\{found_idx}"
    (self, label)
  } else {
    let label = ".Lstr\{self.string_counter}"
    let g = {
      ..self,
      string_counter: self.string_counter + 1,
      strings: self.strings + [s],
    }
    (g, label)
  }
}

///|
fn CodeGen::add_float(self : CodeGen, f : Double) -> (CodeGen, String) {
  let label = ".Lflt\{self.float_counter}"
  let g = {
    ..self,
    float_counter: self.float_counter + 1,
    floats: self.floats + [f],
  }
  (g, label)
}

///|
fn is_float_expr(expr : AST, var_is_float : Map[String, Bool]) -> Bool {
  match expr {
    Float(_) => true
    Ident(name) => var_is_float.get(name) == Some(true)
    Binary(_, left, right) =>
      is_float_expr(left, var_is_float) || is_float_expr(right, var_is_float)
    Unary(_, e) => is_float_expr(e, var_is_float)
    CallExpr(Ident(fname), _) => fname == "string_to_float"
    _ => false
  }
}

///|
fn is_float_field_expr(
  expr : AST,
  var_tuple_field_types : Map[String, Array[Bool]],
) -> Bool {
  match expr {
    FieldExpr(Ident(var_name), field) => {
      let idx = if field.length() > 0 {
        let c = field[0]
        if c >= '0' && c <= '9' {
          c.to_int() - 48
        } else {
          -1
        }
      } else {
        -1
      }
      if idx >= 0 {
        match var_tuple_field_types.get(var_name) {
          Some(types) => idx < types.length() && types[idx]
          None => false
        }
      } else {
        false
      }
    }
    _ => false
  }
}

///|
fn is_int_expr(
  expr : AST,
  var_is_float : Map[String, Bool],
  var_is_map : Map[String, Bool],
) -> Bool {
  match expr {
    Int(_) => true
    Bool(_) => true
    Char(_) => true
    Unary("-", e) => is_int_expr(e, var_is_float, var_is_map)
    Unary("!", e) => is_int_expr(e, var_is_float, var_is_map)
    Binary(op, left, right) => {
      let is_cmp = op == "==" ||
        op == "!=" ||
        op == "<" ||
        op == ">" ||
        op == "<=" ||
        op == ">="
      let is_arith = op == "+" ||
        op == "-" ||
        op == "*" ||
        op == "/" ||
        op == "%"
      let is_bit = op == "&" ||
        op == "|" ||
        op == "^" ||
        op == "<<" ||
        op == ">>"
      (is_cmp || is_arith || is_bit) &&
      !is_float_expr(left, var_is_float) &&
      !is_float_expr(right, var_is_float)
    }
    Ident(name) =>
      var_is_map.get(name) != Some(true) &&
      (var_is_float.get(name) == Some(false) || var_is_float.get(name) == None)
    FieldExpr(_, _) => true
    IndexExpr(_, _) => true
    CallExpr(FieldExpr(_, method), _) => method == "length"
    _ => false
  }
}

///|
fn is_array_expr(expr : AST, var_array_len : Map[String, Int]) -> Bool {
  match expr {
    ArrayLit(_) => true
    Ident(name) => var_array_len.get(name) != None
    Binary("+", left, right) =>
      is_array_expr(left, var_array_len) && is_array_expr(right, var_array_len)
    _ => false
  }
}

///|
fn is_string_expr(expr : AST, var_is_string : Map[String, Bool]) -> Bool {
  match expr {
    String(_) => true
    StringConcat(_) => true
    Ident(name) => var_is_string.get(name) == Some(true)
    Binary("+", left, right) =>
      is_string_expr(left, var_is_string) ||
      is_string_expr(right, var_is_string)
    CallExpr(Ident(fname), _) =>
      fname == "string_concat" ||
      fname == "input" ||
      fname == "int_to_string" ||
      fname == "float_to_string"
    _ => false
  }
}

///|
fn is_char_expr(expr : AST, var_is_char : Map[String, Bool]) -> Bool {
  match expr {
    Char(_) => true
    Ident(name) => var_is_char.get(name) == Some(true)
    CallExpr(FieldExpr(_, "unwrap"), _) => true // unwrap returns the inner type
    _ => false
  }
}

///|
fn is_map_expr(expr : AST, var_is_map : Map[String, Bool]) -> Bool {
  match expr {
    MapLit(_) => true
    Ident(name) => var_is_map.get(name) == Some(true)
    _ => false
  }
}

///|
fn is_struct_expr(expr : AST, var_types : Map[String, String]) -> Bool {
  match expr {
    StructLit(_type_name, _fields) => true
    StructUpdate(_, _) => true
    Ident(name) => var_types.get(name) != None
    _ => false
  }
}

///|
fn is_bool_expr(expr : AST, var_is_bool : Map[String, Bool]) -> Bool {
  match expr {
    Bool(_) => true
    Ident(name) => var_is_bool.get(name) == Some(true)
    Unary("!", _) => true
    Binary(op, _, _) =>
      op == "==" ||
      op == "!=" ||
      op == "<" ||
      op == ">" ||
      op == "<=" ||
      op == ">=" ||
      op == "&&" ||
      op == "||"
    _ => false
  }
}

///|
fn get_struct_field_names(
  expr : AST,
  var_struct_fields : Map[String, Array[String]],
  var_types : Map[String, String],
  struct_fields : Map[String, Array[String]],
) -> Array[String]? {
  match expr {
    Ident(var_name) =>
      match var_struct_fields.get(var_name) {
        Some(fields) => Some(fields)
        None =>
          match var_types.get(var_name) {
            Some(type_name) => struct_fields.get(type_name)
            None => None
          }
      }
    StructLit(_, fields) => {
      let names = fields.map(fn(pair) {
        let (name, _) = pair
        name
      })
      Some(names)
    }
    _ => None
  }
}

///|
fn CodeGen::emit_call_print(self : CodeGen) -> CodeGen {
  let g = self.emit_inst(Mov(Reg64("rax"), Imm32(1)))
  let g = g.emit_inst(Mov(Reg64("rdi"), Imm32(1)))
  g.emit_inst(Syscall)
}

///|
fn CodeGen::codegen_user_func_call2(
  self : CodeGen,
  func_name : String,
  args : Array[AST],
) -> CodeGen {
  let arg_regs = ["rdi", "rsi", "rdx", "rcx", "r8", "r9"]
  let mut g = self
  let num_args = args.length()
  let mut i = num_args - 1
  while i >= 0 {
    g = g.codegen_expr(args[i])
    g = g.emit_inst(Push(Reg64("rax")))
    i = i - 1
  }
  let mut j = 0
  while j < num_args {
    if j < 6 {
      g = g.emit_inst(Pop(Reg64(arg_regs[j])))
    }
    j = j + 1
  }
  g = g.emit_inst(Call(func_name))
  if num_args > 6 {
    let cleanup = (num_args - 6) * 8
    g = g.emit_inst(Add(Reg64("rsp"), Imm32(cleanup)))
  }
  g
}

///|
fn CodeGen::codegen_expr(self : CodeGen, expr : AST) -> CodeGen {
  match expr {
    Int(n) => {
      let g = self.emit_inst(Mov(Reg64("rax"), Imm32(n)))
      g
    }
    Bool(b) => {
      let g = self.emit_inst(Mov(Reg64("rax"), Imm32(if b { 1 } else { 0 })))
      g
    }
    Char(c) => {
      let code = c.to_int()
      let g = self.emit_inst(Mov(Reg64("rax"), Imm32(code)))
      g
    }
    String(s) => {
      let (g, label) = self.add_string(s)
      let g = g.emit_inst(Lea(Reg64("rax"), RipRel32(label)))
      g
    }
    Spread(_) => self
    StringConcat(parts) =>
      // Build concatenation from left to right: "a" + "b" + "c" becomes ((a + b) + c)
      // Use Binary("+", ...) to leverage existing string concatenation codegen
      if parts.length() == 0 {
        let (g2, label) = self.add_string("")
        g2.emit_inst(Lea(Reg64("rax"), RipRel32(label)))
      } else if parts.length() == 1 {
        self.codegen_expr(parts[0])
      } else {
        // Start with first part, then chain with Binary("+", left, right)
        let mut result_expr = parts[0]
        let mut i = 1
        while i < parts.length() {
          result_expr = Binary("+", result_expr, parts[i])
          i = i + 1
        }
        self.codegen_expr(result_expr)
      }
    Float(f) => {
      let (g, label) = self.add_float(f)
      let g = g.emit_inst(Movsd(Xmm("xmm0"), RipRel32(label)))
      let g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
      g
    }
    Ident(name) =>
      match self.var_offsets.get(name) {
        Some(offset) =>
          if self.var_is_float.get(name) == Some(true) {
            let g = self.emit_inst(Movsd(Xmm("xmm0"), StackBP64(offset)))
            let g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
            g
          } else if self.var_array_len.get(name) != None {
            // Array - load the address from stack (rbp + offset)
            let g = self.emit_inst(Mov(Reg64("rax"), StackBP64(offset)))
            g
          } else if self.var_is_tuple.get(name) == Some(true) {
            // Tuple - return address (rbp + offset)
            let g = self.emit_inst(Mov(Reg64("rax"), Reg64("rbp")))
            let g = if offset >= 0 {
              g.emit_inst(Add(Reg64("rax"), Imm32(offset)))
            } else {
              g.emit_inst(Sub(Reg64("rax"), Imm32(-offset)))
            }
            g
          } else if self.var_struct_fields.get(name) != None {
            // Struct - return address (rbp + offset)
            let g = self.emit_inst(Mov(Reg64("rax"), Reg64("rbp")))
            let g = if offset >= 0 {
              g.emit_inst(Add(Reg64("rax"), Imm32(offset)))
            } else {
              g.emit_inst(Sub(Reg64("rax"), Imm32(-offset)))
            }
            g
          } else if self.var_is_string.get(name) == Some(true) {
            // String - load the address from stack (rbp + offset)
            let g = self.emit_inst(Mov(Reg64("rax"), StackBP64(offset)))
            g
          } else if self.var_is_char.get(name) == Some(true) {
            // Char - load from stack
            let g = self.emit_inst(Mov(Reg64("rax"), StackBP64(offset)))
            g
          } else {
            let g = self.emit_inst(Mov(Reg64("rax"), StackBP64(offset)))
            g
          }
        None => {
          let disc_val = match self.enum_discriminants.get(name) {
            Some(disc) => Some(disc)
            None => {
              let parts = name.split("::").to_array()
              if parts.length() == 2 {
                self.enum_discriminants.get(parts[1].to_string())
              } else {
                None
              }
            }
          }
          match disc_val {
            Some(disc) => {
              let g = self.emit_inst(Mov(Reg64("rax"), Imm32(disc)))
              g
            }
            None => {
              let g = self.emit_inst(Mov(Reg64("rax"), Imm32(0)))
              g
            }
          }
        }
      }
    Binary(op, left, right) => {
      let is_float = is_float_expr(left, self.var_is_float) ||
        is_float_expr(right, self.var_is_float)
      let is_string = is_string_expr(left, self.var_is_string) ||
        is_string_expr(right, self.var_is_string)
      let is_string_concat = op == "+" &&
        is_string_expr(left, self.var_is_string) &&
        is_string_expr(right, self.var_is_string)
      if is_string && (op == "==" || op == "!=") {
        let g = self.codegen_expr(left)
        let g = g.emit_inst(Push(Reg64("rax")))
        let g = g.codegen_expr(right)
        let g = g.emit_inst(Pop(Reg64("rsi")))
        let g = g.emit_inst(Mov(Reg64("rdi"), Reg64("rax")))
        let loop_label = ".Lstrcmp_loop\{self.label_counter}"
        let end_label = ".Lstrcmp_end\{self.label_counter}"
        let g = { ..g, label_counter: g.label_counter + 1 }
        let g = g.define_label(loop_label)
        let g = g.emit_inst(Mov(Reg64("rax"), MemIndirect("rsi")))
        let g = g.emit_inst(Movzx(Reg64("rcx"), Reg8("al")))
        let g = g.emit_inst(Mov(Reg64("rax"), MemIndirect("rdi")))
        let g = g.emit_inst(Movzx(Reg64("rdx"), Reg8("al")))
        let g = g.emit_inst(Cmp(Reg64("rcx"), Reg64("rdx")))
        let g = g.emit_inst(Jne(end_label))
        let g = g.emit_inst(Cmp(Reg64("rcx"), Imm32(0)))
        let g = g.emit_inst(Je(end_label))
        let g = g.emit_inst(Inc(Reg64("rsi")))
        let g = g.emit_inst(Inc(Reg64("rdi")))
        let g = g.emit_inst(Jmp(loop_label))
        let g = g.define_label(end_label)
        let g = g.emit_inst(Cmp(Reg64("rcx"), Reg64("rdx")))
        if op == "==" {
          let g = g.emit_inst(Setz(Reg64("al")))
          let g = g.emit_inst(Movzx(Reg64("rax"), Reg8("al")))
          g
        } else {
          let g = g.emit_inst(Setnz(Reg64("al")))
          let g = g.emit_inst(Movzx(Reg64("rax"), Reg8("al")))
          g
        }
      } else if op == "+" &&
        is_array_expr(left, self.var_array_len) &&
        is_array_expr(right, self.var_array_len) {
        self.codegen_expr(ArrayLit([Spread(left), Spread(right)]))
      } else if is_string_concat {
        // String concatenation
        let mut g = self
        // Evaluate first string
        g = g.codegen_expr(left)
        g = g.emit_inst(Push(Reg64("rax")))
        // Evaluate second string
        g = g.codegen_expr(right)
        // Move to rdi (second arg)
        g = g.emit_inst(Mov(Reg64("rdi"), Reg64("rax")))
        // Pop first to rsi (first arg)
        g = g.emit_inst(Pop(Reg64("rsi")))
        // Inline the string_concat code
        let (g2, copy1_loop) = g.new_label()
        let (g3, copy1_done) = g2.new_label()
        let (g4, copy2_loop) = g3.new_label()
        let (g5, copy2_done) = g4.new_label()
        g = g5
        g = g.emit_inst(Push(Reg64("rbx")))
        g = g.emit_inst(Push(Reg64("rcx")))
        let buf_label = ".Lstrcat_buf"
        g = g.emit_inst(Lea(Reg64("rax"), RipRel32(buf_label)))
        g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rax")))
        g = g.emit_inst(Mov(Reg64("rcx"), Imm32(0)))
        g = g.define_label(copy1_loop)
        g = g.emit_inst(Movzx(Reg64("rax"), MemIndirect("rsi")))
        g = g.emit_inst(Test(Reg64("rax"), Reg64("rax")))
        g = g.emit_inst(Jz(copy1_done))
        g = g.emit_inst(Mov(MemIndirect("rbx"), Reg8("al")))
        g = g.emit_inst(Inc(Reg64("rbx")))
        g = g.emit_inst(Inc(Reg64("rsi")))
        g = g.emit_inst(Inc(Reg64("rcx")))
        g = g.emit_inst(Jmp(copy1_loop))
        g = g.define_label(copy1_done)
        g = g.define_label(copy2_loop)
        g = g.emit_inst(Movzx(Reg64("rax"), MemIndirect("rdi")))
        g = g.emit_inst(Test(Reg64("rax"), Reg64("rax")))
        g = g.emit_inst(Jz(copy2_done))
        g = g.emit_inst(Mov(MemIndirect("rbx"), Reg8("al")))
        g = g.emit_inst(Inc(Reg64("rbx")))
        g = g.emit_inst(Inc(Reg64("rdi")))
        g = g.emit_inst(Inc(Reg64("rcx")))
        g = g.emit_inst(Jmp(copy2_loop))
        g = g.define_label(copy2_done)
        g = g.emit_inst(Mov(Reg8("al"), Imm8(0)))
        g = g.emit_inst(Mov(MemIndirect("rbx"), Reg8("al")))
        g = g.emit_inst(Lea(Reg64("rax"), RipRel32(buf_label)))
        g = g.emit_inst(Pop(Reg64("rcx")))
        g = g.emit_inst(Pop(Reg64("rbx")))
        g
      } else if op == "+" && is_string {
        // String + non-string concatenation: convert non-string to string first
        let left_is_string = is_string_expr(left, self.var_is_string)
        if left_is_string {
          // string + expr: convert expr to string, then do string + string concat
          // Convert right to int_to_string(right)
          let right_as_string = CallExpr(Ident("int_to_string"), [right])
          let concat_expr = Binary("+", left, right_as_string)
          self.codegen_expr(concat_expr)
        } else {
          // expr + string: convert expr to string, then do string + string concat
          let left_as_string = CallExpr(Ident("int_to_string"), [left])
          let concat_expr = Binary("+", left_as_string, right)
          self.codegen_expr(concat_expr)
        }
      } else if is_float {
        let g = self.codegen_expr(left)
        let g = g.emit_inst(PushXmm("xmm0"))
        let g = g.codegen_expr(right)
        let g = g.emit_inst(PopXmm("xmm1"))
        match op {
          "+" => {
            let g = g.emit_inst(Addsd(Xmm("xmm0"), Xmm("xmm1")))
            let g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
            g
          }
          "-" => {
            let g = g.emit_inst(Subsd(Xmm("xmm1"), Xmm("xmm0")))
            let g = g.emit_inst(Movsd(Xmm("xmm0"), Xmm("xmm1")))
            let g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
            g
          }
          "*" => {
            let g = g.emit_inst(Mulsd(Xmm("xmm0"), Xmm("xmm1")))
            let g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
            g
          }
          "/" => {
            let g = g.emit_inst(Divsd(Xmm("xmm1"), Xmm("xmm0")))
            let g = g.emit_inst(Movsd(Xmm("xmm0"), Xmm("xmm1")))
            let g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
            g
          }
          "==" | "!=" | "<" | ">" | "<=" | ">=" => {
            let g = g.emit_inst(Ucomisd(Xmm("xmm1"), Xmm("xmm0")))
            let end_label = ".Lcmp_end\{self.label_counter}"
            let g = { ..g, label_counter: g.label_counter + 1 }
            let g = g.emit_inst(Mov(Reg64("rax"), Imm32(0)))
            match op {
              "==" => {
                let g = g.emit_inst(Jne(end_label))
                let g = g.emit_inst(Jp(end_label))
                let g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                g.define_label(end_label)
              }
              "!=" => {
                let g = g.emit_inst(Jne(end_label))
                let g = g.emit_inst(Jp(end_label))
                let g = g.emit_inst(Mov(Reg64("rax"), Imm32(0)))
                let g = g.define_label(end_label)
                let g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                g
              }
              "<" => {
                let g = g.emit_inst(Ja(end_label))
                let g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                g.define_label(end_label)
              }
              ">" => {
                let g = g.emit_inst(Jb(end_label))
                let g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                g.define_label(end_label)
              }
              "<=" => {
                let g = g.emit_inst(Ja(end_label))
                let g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                g.define_label(end_label)
              }
              ">=" => {
                let g = g.emit_inst(Jb(end_label))
                let g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                g.define_label(end_label)
              }
              _ => g
            }
          }
          _ => {
            let g = g.emit_inst(Mov(Reg64("rax"), Imm32(0)))
            g
          }
        }
      } else {
        let g = self.codegen_expr(left)
        let g = g.emit_inst(Push(Reg64("rax")))
        let g = g.codegen_expr(right)
        let g = g.emit_inst(Pop(Reg64("rcx")))
        match op {
          "+" => {
            let g = g.emit_inst(Add(Reg64("rax"), Reg64("rcx")))
            g
          }
          "-" => {
            let g = g.emit_inst(Sub(Reg64("rcx"), Reg64("rax")))
            let g = g.emit_inst(Mov(Reg64("rax"), Reg64("rcx")))
            g
          }
          "*" => {
            let g = g.emit_inst(Imul(Reg64("rax"), Reg64("rcx")))
            g
          }
          "==" => {
            let g = g.emit_inst(Cmp(Reg64("rcx"), Reg64("rax")))
            let g = g.emit_inst(Setz(Reg64("al")))
            let g = g.emit_inst(Mov(Reg64("rax"), Reg64("rax")))
            g
          }
          "!=" => {
            let g = g.emit_inst(Cmp(Reg64("rcx"), Reg64("rax")))
            let g = g.emit_inst(Setnz(Reg64("al")))
            let g = g.emit_inst(Mov(Reg64("rax"), Reg64("rax")))
            g
          }
          "<" => {
            let g = g.emit_inst(Cmp(Reg64("rcx"), Reg64("rax")))
            let g = g.emit_inst(Setl(Reg64("al")))
            let g = g.emit_inst(Mov(Reg64("rax"), Reg64("rax")))
            g
          }
          ">" => {
            let g = g.emit_inst(Cmp(Reg64("rcx"), Reg64("rax")))
            let g = g.emit_inst(Setg(Reg64("al")))
            let g = g.emit_inst(Mov(Reg64("rax"), Reg64("rax")))
            g
          }
          "<=" => {
            let g = g.emit_inst(Cmp(Reg64("rcx"), Reg64("rax")))
            let g = g.emit_inst(Setle(Reg64("al")))
            let g = g.emit_inst(Mov(Reg64("rax"), Reg64("rax")))
            g
          }
          ">=" => {
            let g = g.emit_inst(Cmp(Reg64("rcx"), Reg64("rax")))
            let g = g.emit_inst(Setge(Reg64("al")))
            let g = g.emit_inst(Mov(Reg64("rax"), Reg64("rax")))
            g
          }
          "/" => {
            let g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rax")))
            let g = g.emit_inst(Mov(Reg64("rax"), Reg64("rcx")))
            let g = g.emit_inst(Cqo)
            let g = g.emit_inst(Idiv(Reg64("rbx")))
            g
          }
          "%" => {
            let g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rax")))
            let g = g.emit_inst(Mov(Reg64("rax"), Reg64("rcx")))
            let g = g.emit_inst(Cqo)
            let g = g.emit_inst(Idiv(Reg64("rbx")))
            let g = g.emit_inst(Mov(Reg64("rax"), Reg64("rdx")))
            g
          }
          "&" => {
            let g = g.emit_inst(And(Reg64("rcx"), Reg64("rax")))
            let g = g.emit_inst(Mov(Reg64("rax"), Reg64("rcx")))
            g
          }
          "|" => {
            let g = g.emit_inst(Or(Reg64("rcx"), Reg64("rax")))
            let g = g.emit_inst(Mov(Reg64("rax"), Reg64("rcx")))
            g
          }
          "^" => {
            let g = g.emit_inst(Xor(Reg64("rcx"), Reg64("rax")))
            let g = g.emit_inst(Mov(Reg64("rax"), Reg64("rcx")))
            g
          }
          "<<" => {
            let g = g.emit_inst(Push(Reg64("rax")))
            let g = g.emit_inst(Mov(Reg64("rax"), Reg64("rcx")))
            let g = g.emit_inst(Pop(Reg64("rcx")))
            g.emit_inst(Shl(Reg64("rax"), Reg64("cl")))
          }
          ">>" => {
            let g = g.emit_inst(Push(Reg64("rax")))
            let g = g.emit_inst(Mov(Reg64("rax"), Reg64("rcx")))
            let g = g.emit_inst(Pop(Reg64("rcx")))
            g.emit_inst(Sar(Reg64("rax"), Reg64("cl")))
          }
          _ => g
        }
      }
    }
    Unary(op, e) => {
      let g = self.codegen_expr(e)
      match op {
        "-" => {
          let g = g.emit_inst(Neg(Reg64("rax")))
          g
        }
        "!" => {
          let g = g.emit_inst(Cmp(Reg64("rax"), Imm32(0)))
          let g = g.emit_inst(Setz(Reg64("al")))
          g
        }
        _ => g
      }
    }
    CallExpr(func, args) =>
      match func {
        FieldExpr(obj, method_name) =>
          match method_name {
            "length" => {
              // Check if it's a string or array
              let is_str = is_string_expr(obj, self.var_is_string)
              if is_str {
                // String length - count chars until null terminator
                let mut g = self.codegen_expr(obj)
                let (g2, len_loop) = g.new_label()
                let (g3, len_done) = g2.new_label()
                g = g3
                g = g.emit_inst(Push(Reg64("rbx")))
                g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rax")))
                g = g.emit_inst(Mov(Reg64("rax"), Imm32(0)))
                g = g.define_label(len_loop)
                g = g.emit_inst(Movzx(Reg64("rcx"), MemIndirect("rbx")))
                g = g.emit_inst(Test(Reg64("rcx"), Reg64("rcx")))
                g = g.emit_inst(Jz(len_done))
                g = g.emit_inst(Inc(Reg64("rbx")))
                g = g.emit_inst(Inc(Reg64("rax")))
                g = g.emit_inst(Jmp(len_loop))
                g = g.define_label(len_done)
                g = g.emit_inst(Pop(Reg64("rbx")))
                g
              } else {
                // Array length - read from array header
                let g = self.codegen_expr(obj)
                g.emit_inst(Mov(Reg64("rax"), MemIndirect("rax")))
              }
            }
            "get_char" => {
              // str.get_char(index) - returns char at index
              // String is stored as address, we just get the byte at that offset
              let mut g = self
              // Evaluate the string
              g = g.codegen_expr(obj)
              g = g.emit_inst(Push(Reg64("rax"))) // save string address
              // Evaluate index
              g = g.codegen_expr(args[0])
              // rax = index
              // Add to string address
              g = g.emit_inst(Pop(Reg64("rcx"))) // rcx = string address
              g = g.emit_inst(Add(Reg64("rcx"), Reg64("rax"))) // rcx = address + index
              // Load byte and zero-extend to 32 bits
              g = g.emit_inst(Movzx(Reg64("rax"), MemIndirect("rcx")))
              g
            }
            "push" =>
              match obj {
                Ident(var_name) => {
                  // arr.push(value) - add element to array
                  // Array layout: [length][elem0][elem1]...
                  let mut g = self
                  // 1. Evaluate the value to push first (to avoid register conflicts)
                  g = g.codegen_expr(args[0])
                  g = g.emit_inst(Push(Reg64("rax"))) // stack: [value]
                  // 2. Get array address
                  g = g.codegen_expr(obj)
                  g = g.emit_inst(Push(Reg64("rax"))) // stack: [value, array_addr]
                  // 3. Load current length
                  g = g.emit_inst(Mov(Reg64("rax"), MemIndirect("rax")))
                  // rax = length
                  g = g.emit_inst(Mov(Reg64("rcx"), Imm32(8)))
                  g = g.emit_inst(Imul(Reg64("rax"), Reg64("rcx"))) // rax = length * 8
                  // 4. Get array address back
                  g = g.emit_inst(Pop(Reg64("rcx"))) // rcx = array_addr, stack: [value]
                  g = g.emit_inst(Add(Reg64("rax"), Reg64("rcx"))) // rax = array_addr + length*8
                  g = g.emit_inst(Add(Reg64("rax"), Imm32(8))) // rax = array_addr + 8 + length*8 = position for new element
                  // 5. Store the value
                  g = g.emit_inst(Pop(Reg64("rcx"))) // rcx = value, stack: empty
                  g = g.emit_inst(Mov(MemIndirect("rax"), Reg64("rcx")))
                  // 6. Increment length in header
                  g = g.codegen_expr(obj)
                  g = g.emit_inst(Mov(Reg64("rcx"), MemIndirect("rax")))
                  g = g.emit_inst(Inc(Reg64("rcx")))
                  g = g.emit_inst(Mov(MemIndirect("rax"), Reg64("rcx")))
                  g
                }
                _ => self.emit_inst(Mov(Reg64("rax"), Imm32(0)))
              }
            "unwrap" => {
              // For unwrap on Option types - evaluate the object first, then return value
              // The object expression result (e.g., get_char result) should be in rax
              let g = self.codegen_expr(obj)
              g
            }
            "to_string" => {
              // int.to_string() - convert integer to string
              // Simplified: just return pointer to int buffer like print does
              let g = self.codegen_expr(obj)
              // Just return the value as is - the buffer will be filled by caller
              // This is a placeholder - proper implementation would return a proper string
              g.emit_inst(Mov(Reg64("rax"), Imm32(0)))
            }
            _ => self.emit_inst(Mov(Reg64("rax"), Imm32(0)))
          }
        _ => {
          let func_name = match func {
            Ident(name) => name
            _ => ""
          }
          match func_name {
            "println" | "print" => {
              let is_println = func_name == "println"
              let mut g = self
              let mut arg_idx = 0
              let skip_print_label = ".Lskip_print\{g.label_counter}"
              g = { ..g, label_counter: g.label_counter + 1 }
              let mut need_skip_print = false
              while arg_idx < args.length() {
                let arg = args[arg_idx]
                match arg {
                  String(s) => {
                    let (g2, label) = g.add_string(s)
                    g = g2
                    g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(label)))
                    g = g.emit_inst(Mov(Reg64("rdx"), Imm32(s.length())))
                  }
                  Int(n) => {
                    let s = n.to_string()
                    let (g2, label) = g.add_string(s)
                    g = g2
                    g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(label)))
                    g = g.emit_inst(Mov(Reg64("rdx"), Imm32(s.length())))
                  }
                  Float(f) => {
                    let s = f.to_string()
                    let (g2, label) = g.add_string(s)
                    g = g2
                    g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(label)))
                    g = g.emit_inst(Mov(Reg64("rdx"), Imm32(s.length())))
                  }
                  Char(c) => {
                    let s = c.to_string()
                    let (g2, label) = g.add_string(s)
                    g = g2
                    g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(label)))
                    g = g.emit_inst(Mov(Reg64("rdx"), Imm32(1)))
                  }
                  Bool(b) => {
                    let s = if b { "true" } else { "false" }
                    let (g2, label) = g.add_string(s)
                    g = g2
                    g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(label)))
                    g = g.emit_inst(Mov(Reg64("rdx"), Imm32(s.length())))
                  }
                  Ident(var_name) =>
                    if g.var_array_len.get(var_name) != None {
                      // Print array - iterate through elements
                      // Use callee-saved registers to avoid stack offset issues
                      g = g.codegen_expr(arg)
                      // rax = array address
                      // Save callee-saved registers first
                      g = g.emit_inst(Push(Reg64("rbx")))
                      g = g.emit_inst(Push(Reg64("r12")))
                      g = g.emit_inst(Push(Reg64("r13")))
                      g = g.emit_inst(Push(Reg64("r14")))
                      g = g.emit_inst(Push(Reg64("r15")))
                      // r12 = array address
                      g = g.emit_inst(Mov(Reg64("r12"), Reg64("rax")))
                      // r13 = array length  
                      g = g.emit_inst(Mov(Reg64("r13"), MemIndirect("rax")))
                      // r14 = counter (starts at 0)
                      g = g.emit_inst(Mov(Reg64("r14"), Imm32(0)))
                      // Print opening bracket
                      let (g2, open_label) = g.add_string("[")
                      g = g2
                      g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(open_label)))
                      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(1)))
                      g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                      g = g.emit_inst(Mov(Reg64("rdi"), Imm32(1)))
                      g = g.emit_inst(Syscall)
                      // Loop labels
                      let arr_loop = ".Larr_print_loop\{g.label_counter}"
                      let arr_done = ".Larr_print_done\{g.label_counter}"
                      let elem_print = ".Larr_elem_print\{g.label_counter + 1}"
                      g = { ..g, label_counter: g.label_counter + 2 }
                      g = g.define_label(arr_loop)
                      // Check if counter >= length (exit if counter >= length)
                      g = g.emit_inst(Mov(Reg64("rax"), Reg64("r14")))
                      g = g.emit_inst(Cmp(Reg64("rax"), Reg64("r13")))
                      g = g.emit_inst(Jae(arr_done))
                      // Print comma before element (if not first)
                      g = g.emit_inst(Cmp(Reg64("r14"), Imm32(0)))
                      g = g.emit_inst(Je(elem_print))
                      // Print ", "
                      let (g3, comma_label) = g.add_string(", ")
                      g = g3
                      g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(comma_label)))
                      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(2)))
                      g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                      g = g.emit_inst(Mov(Reg64("rdi"), Imm32(1)))
                      g = g.emit_inst(Syscall)
                      g = g.define_label(elem_print)
                      // Load element: array_addr + 8 + counter*8
                      g = g.emit_inst(Mov(Reg64("rax"), Reg64("r14")))
                      g = g.emit_inst(Mov(Reg64("rcx"), Imm32(8)))
                      g = g.emit_inst(Imul(Reg64("rax"), Reg64("rcx")))
                      g = g.emit_inst(Mov(Reg64("rbx"), Reg64("r12")))
                      g = g.emit_inst(Add(Reg64("rbx"), Reg64("rax")))
                      g = g.emit_inst(Add(Reg64("rbx"), Imm32(8)))
                      g = g.emit_inst(Mov(Reg64("rax"), MemIndirect("rbx")))
                      // Convert element to string and print
                      // Save the element value in r15
                      g = g.emit_inst(Mov(Reg64("r15"), Reg64("rax")))
                      let buf_label = ".Lint_buf"
                      let (g4, digit_loop) = g.new_label()
                      let (g5, done_label) = g4.new_label()
                      let (g6, skip_zero) = g5.new_label()
                      let (g7, skip_zero_end) = g6.new_label()
                      g = g7
                      g = g.emit_inst(Mov(Reg64("rbx"), Reg64("r15")))
                      g = g.emit_inst(Lea(Reg64("rdi"), RipRel32(buf_label)))
                      g = g.emit_inst(Add(Reg64("rdi"), Imm32(30)))
                      g = g.emit_inst(Mov(Reg64("rcx"), Imm32(0)))
                      g = g.emit_inst(Cmp(Reg64("rbx"), Imm32(0)))
                      g = g.emit_inst(Je(done_label))
                      g = g.define_label(digit_loop)
                      g = g.emit_inst(Mov(Reg64("rax"), Reg64("rbx")))
                      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(0)))
                      g = g.emit_inst(Mov(Reg64("rsi"), Imm32(10)))
                      g = g.emit_inst(Idiv(Reg64("rsi")))
                      g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rax")))
                      g = g.emit_inst(Add(Reg64("rdx"), Imm32(48)))
                      g = g.emit_inst(Mov(Reg8("sil"), Reg8("dl")))
                      g = g.emit_inst(Mov(MemIndirect("rdi"), Reg8("sil")))
                      g = g.emit_inst(Dec(Reg64("rdi")))
                      g = g.emit_inst(Inc(Reg64("rcx")))
                      g = g.emit_inst(Cmp(Reg64("rbx"), Imm32(0)))
                      g = g.emit_inst(Jne(digit_loop))
                      g = g.define_label(done_label)
                      g = g.emit_inst(Cmp(Reg64("rcx"), Imm32(0)))
                      g = g.emit_inst(Jne(skip_zero))
                      g = g.emit_inst(Mov(Reg8("sil"), Imm8(48)))
                      g = g.emit_inst(Mov(MemIndirect("rdi"), Reg8("sil")))
                      g = g.emit_inst(Inc(Reg64("rcx")))
                      g = g.emit_inst(Jmp(skip_zero_end))
                      g = g.define_label(skip_zero)
                      g = g.emit_inst(Inc(Reg64("rdi")))
                      g = g.define_label(skip_zero_end)
                      g = g.emit_inst(Mov(Reg64("rsi"), Reg64("rdi")))
                      g = g.emit_inst(Mov(Reg64("rdx"), Reg64("rcx")))
                      // Print the number
                      g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                      g = g.emit_inst(Mov(Reg64("rdi"), Imm32(1)))
                      g = g.emit_inst(Syscall)
                      // Increment counter
                      g = g.emit_inst(Inc(Reg64("r14")))
                      g = g.emit_inst(Jmp(arr_loop))
                      g = g.define_label(arr_done)
                      // Print closing bracket
                      let (g8, close_label) = g.add_string("]")
                      g = g8
                      g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(close_label)))
                      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(1)))
                      g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                      g = g.emit_inst(Mov(Reg64("rdi"), Imm32(1)))
                      g = g.emit_inst(Syscall)
                      // Restore callee-saved registers
                      g = g.emit_inst(Pop(Reg64("r15")))
                      g = g.emit_inst(Pop(Reg64("r14")))
                      g = g.emit_inst(Pop(Reg64("r13")))
                      g = g.emit_inst(Pop(Reg64("r12")))
                      g = g.emit_inst(Pop(Reg64("rbx")))
                      need_skip_print = true
                      g = g.emit_inst(Jmp(skip_print_label))
                    } else if is_array_expr(arg, g.var_array_len) {
                      // Array literal - evaluate and print placeholder
                      g = g.codegen_expr(arg)
                      let (g2, label1) = g.add_string("<array>")
                      g = g2
                      g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(label1)))
                      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(7)))
                    } else if g.var_is_string.get(var_name) == Some(true) {
                      // String variable - evaluate and print the string
                      g = g.codegen_expr(arg)
                      // Calculate string length
                      g = g.emit_inst(Mov(Reg64("rsi"), Reg64("rax")))
                      let (g2, len_loop) = g.new_label()
                      let (g3, len_done) = g2.new_label()
                      g = g3
                      g = g.emit_inst(Push(Reg64("rax")))
                      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(0)))
                      g = g.define_label(len_loop)
                      g = g.emit_inst(Movzx(Reg64("rcx"), MemIndirect("rax")))
                      g = g.emit_inst(Cmp(Reg64("rcx"), Imm32(0)))
                      g = g.emit_inst(Je(len_done))
                      g = g.emit_inst(Inc(Reg64("rax")))
                      g = g.emit_inst(Inc(Reg64("rdx")))
                      g = g.emit_inst(Jmp(len_loop))
                      g = g.define_label(len_done)
                      g = g.emit_inst(Pop(Reg64("rax")))
                      g = g.emit_inst(Mov(Reg64("rsi"), Reg64("rax")))
                    } else if g.var_is_char.get(var_name) == Some(true) {
                      // Char variable - evaluate and print as 1-char string
                      g = g.codegen_expr(arg)
                      // rax has char code, put it in buffer and print
                      g = g.emit_inst(Push(Reg64("rax")))
                      let buf_label = ".Lint_buf"
                      g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(buf_label)))
                      g = g.emit_inst(Pop(Reg64("rax")))
                      g = g.emit_inst(Mov(MemIndirect("rsi"), Reg8("al")))
                      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(1)))
                    } else if g.var_is_float.get(var_name) == Some(true) {
                      // Float variable - print float value
                      g = g.codegen_expr(arg)
                      let flt_buf = ".Lflt_buf"
                      g = g.emit_inst(Push(Reg64("rbx")))
                      g = g.emit_inst(Push(Reg64("rcx")))
                      g = g.emit_inst(Push(Reg64("r8")))
                      g = g.emit_inst(Push(Reg64("r9")))
                      g = g.emit_inst(Push(Reg64("r10")))
                      g = g.emit_inst(Push(Reg64("r11")))
                      g = g.emit_inst(Push(Reg64("r12")))
                      g = g.emit_inst(Push(Reg64("r13")))
                      let (g1, pos_lbl) = g.new_label()
                      let (g2, exp_lbl) = g1.add_float(10000000000000000.0)
                      let (g3, half_lbl) = g2.add_float(0.5)
                      g = g3
                      g = g.emit_inst(Mov(Reg64("r10"), Imm32(0)))
                      g = g.emit_inst(Push(Reg64("rax")))
                      g = g.emit_inst(Sub(Reg64("rsp"), Imm32(16)))
                      g = g.emit_inst(Movsd(MemIndirect("rsp"), Xmm("xmm0")))
                      g = g.emit_inst(Mov(Reg64("r9"), MemIndirect("rsp")))
                      g = g.emit_inst(Shl(Reg64("r9"), Imm8(1)))
                      g = g.emit_inst(Jae(pos_lbl))
                      g = g.emit_inst(Mov(Reg64("r10"), Imm32(1)))
                      g = g.emit_inst(Shr(Reg64("r9"), Imm8(1)))
                      g = g.emit_inst(Mov(MemIndirect("rsp"), Reg64("r9")))
                      g = g.emit_inst(Movsd(Xmm("xmm0"), MemIndirect("rsp")))
                      g = g.define_label(pos_lbl)
                      g = g.emit_inst(Add(Reg64("rsp"), Imm32(16)))
                      g = g.emit_inst(Pop(Reg64("rax")))

                      // Calculate integer and fraction
                      g = g.emit_inst(Cvttsd2si(Reg64("r8"), Xmm("xmm0"))) // r8 is int part
                      g = g.emit_inst(Cvtsi2sd(Xmm("xmm1"), Reg64("r8")))
                      g = g.emit_inst(Subsd(Xmm("xmm0"), Xmm("xmm1"))) // fraction
                      g = g.emit_inst(Movsd(Xmm("xmm1"), RipRel32(exp_lbl)))
                      g = g.emit_inst(Mulsd(Xmm("xmm0"), Xmm("xmm1")))
                      g = g.emit_inst(Movsd(Xmm("xmm1"), RipRel32(half_lbl)))
                      g = g.emit_inst(Addsd(Xmm("xmm0"), Xmm("xmm1")))
                      g = g.emit_inst(Cvttsd2si(Reg64("r11"), Xmm("xmm0"))) // r11 is 16-digit fraction

                      // Setup buffer and length
                      g = g.emit_inst(Lea(Reg64("rbx"), RipRel32(flt_buf)))
                      g = g.emit_inst(Add(Reg64("rbx"), Imm32(40)))
                      g = g.emit_inst(Mov(Reg64("rcx"), Imm32(0)))

                      // Process fraction (backwards)
                      let (g4, loop_start) = g.new_label()
                      let (g5, frac_done) = g4.new_label()
                      let (g6, print_digit) = g5.new_label()
                      g = g6
                      g = g.emit_inst(Mov(Reg64("r12"), Imm32(16))) // 16 digits
                      g = g.emit_inst(Mov(Reg64("r13"), Imm32(1))) // skipping zeros flag

                      g = g.emit_inst(Cmp(Reg64("r11"), Imm32(0)))
                      g = g.emit_inst(Jne(loop_start))
                      // Exact zero fraction: print '0'
                      g = g.emit_inst(Mov(Reg8("al"), Imm8(48)))
                      g = g.emit_inst(Mov(MemIndirect("rbx"), Reg8("al")))
                      g = g.emit_inst(Dec(Reg64("rbx")))
                      g = g.emit_inst(Inc(Reg64("rcx")))
                      g = g.emit_inst(Jmp(frac_done))

                      g = g.define_label(loop_start)
                      g = g.emit_inst(Cmp(Reg64("r12"), Imm32(0)))
                      g = g.emit_inst(Je(frac_done))
                      g = g.emit_inst(Dec(Reg64("r12")))

                      g = g.emit_inst(Mov(Reg64("rax"), Reg64("r11")))
                      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(0)))
                      g = g.emit_inst(Mov(Reg64("rsi"), Imm32(10)))
                      g = g.emit_inst(Idiv(Reg64("rsi")))
                      g = g.emit_inst(Mov(Reg64("r11"), Reg64("rax"))) // update r11
                      // rdx is next digit from right

                      g = g.emit_inst(Cmp(Reg64("r13"), Imm32(1)))
                      g = g.emit_inst(Jne(print_digit))
                      g = g.emit_inst(Cmp(Reg64("rdx"), Imm32(0)))
                      g = g.emit_inst(Je(loop_start)) // skip trailing zero
                      g = g.emit_inst(Mov(Reg64("r13"), Imm32(0))) // found non-zero
                      g = g.define_label(print_digit)
                      g = g.emit_inst(Add(Reg64("rdx"), Imm32(48)))
                      g = g.emit_inst(Mov(MemIndirect("rbx"), Reg8("dl")))
                      g = g.emit_inst(Dec(Reg64("rbx")))
                      g = g.emit_inst(Inc(Reg64("rcx")))
                      g = g.emit_inst(Jmp(loop_start))

                      g = g.define_label(frac_done)
                      g = g.emit_inst(Mov(Reg8("al"), Imm8(46))) // '.'
                      g = g.emit_inst(Mov(MemIndirect("rbx"), Reg8("al")))
                      g = g.emit_inst(Dec(Reg64("rbx")))
                      g = g.emit_inst(Inc(Reg64("rcx")))

                      // Process integer part (r8)
                      let (g7, int_loop) = g.new_label()
                      g = g7
                      g = g.define_label(int_loop)
                      g = g.emit_inst(Mov(Reg64("rax"), Reg64("r8")))
                      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(0)))
                      g = g.emit_inst(Mov(Reg64("rsi"), Imm32(10)))
                      g = g.emit_inst(Idiv(Reg64("rsi")))
                      g = g.emit_inst(Mov(Reg64("r8"), Reg64("rax")))
                      g = g.emit_inst(Add(Reg64("rdx"), Imm32(48)))
                      g = g.emit_inst(Mov(MemIndirect("rbx"), Reg8("dl")))
                      g = g.emit_inst(Dec(Reg64("rbx")))
                      g = g.emit_inst(Inc(Reg64("rcx")))
                      g = g.emit_inst(Cmp(Reg64("r8"), Imm32(0)))
                      g = g.emit_inst(Jne(int_loop))

                      // Print sign
                      let (g8, end_sign) = g.new_label()
                      g = g8
                      g = g.emit_inst(Cmp(Reg64("r10"), Imm32(0)))
                      g = g.emit_inst(Je(end_sign))
                      g = g.emit_inst(Mov(Reg8("al"), Imm8(45))) // '-'
                      g = g.emit_inst(Mov(MemIndirect("rbx"), Reg8("al")))
                      g = g.emit_inst(Dec(Reg64("rbx")))
                      g = g.emit_inst(Inc(Reg64("rcx")))
                      g = g.define_label(end_sign)

                      // Restore and output
                      g = g.emit_inst(Inc(Reg64("rbx")))
                      g = g.emit_inst(Mov(Reg64("rsi"), Reg64("rbx")))
                      g = g.emit_inst(Mov(Reg64("rdx"), Reg64("rcx")))

                      g = g.emit_inst(Pop(Reg64("r13")))
                      g = g.emit_inst(Pop(Reg64("r12")))
                      g = g.emit_inst(Pop(Reg64("r11")))
                      g = g.emit_inst(Pop(Reg64("r10")))
                      g = g.emit_inst(Pop(Reg64("r9")))
                      g = g.emit_inst(Pop(Reg64("r8")))
                      g = g.emit_inst(Pop(Reg64("rcx")))
                      g = g.emit_inst(Pop(Reg64("rbx")))
                    } else if g.var_is_bool.get(var_name) == Some(true) {
                      // Bool variable - print true/false
                      g = g.codegen_expr(arg)
                      let (g2, true_label) = g.new_label()
                      let (g3, end_label) = g2.new_label()
                      g = g3
                      g = g.emit_inst(Cmp(Reg64("rax"), Imm32(0)))
                      g = g.emit_inst(Je(true_label))
                      let (g4, s_true) = g.add_string("true")
                      g = g4
                      g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(s_true)))
                      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(4)))
                      g = g.emit_inst(Jmp(end_label))
                      g = g.define_label(true_label)
                      let (g5, s_false) = g.add_string("false")
                      g = g5
                      g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(s_false)))
                      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(5)))
                      g = g.define_label(end_label)
                    } else if g.var_is_tuple.get(var_name) == Some(true) {
                      // Tuple variable - print placeholder for now
                      g = g.codegen_expr(arg)
                      let (g2, label1) = g.add_string("<tuple>")
                      g = g2
                      g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(label1)))
                      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(8)))
                    } else if g.var_is_map.get(var_name) == Some(true) {
                      // Map variable - use placeholder for now
                      g = g.codegen_expr(arg)
                      g = g.emit_inst(
                        Lea(Reg64("rsi"), RipRel32(".Lmap_placeholder")),
                      )
                      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(5)))
                      g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                      g = g.emit_inst(Mov(Reg64("rdi"), Imm32(1)))
                      g = g.emit_inst(Syscall)
                      g = g.emit_inst(Jmp(skip_print_label))
                    } else if g.var_types.get(var_name) != None ||
                      is_struct_expr(arg, g.var_types) {
                      // Struct variable - print each field
                      let field_names = get_struct_field_names(
                        arg,
                        g.var_struct_fields,
                        g.var_types,
                        g.struct_fields,
                      )
                      match field_names {
                        Some(fields) => {
                          let base_offset = match g.var_offsets.get(var_name) {
                            Some(off) => off
                            None => 0
                          }
                          // Print '{'
                          let (g2, open_label) = g.add_string("{")
                          g = g2
                          g = g.emit_inst(
                            Lea(Reg64("rsi"), RipRel32(open_label)),
                          )
                          g = g.emit_inst(Mov(Reg64("rdx"), Imm32(1)))
                          g = g.emit_call_print()
                          // Print each field
                          let mut field_idx = 0
                          while field_idx < fields.length() {
                            let field_name = fields[field_idx]
                            // Print field name
                            let (g3, fn_label) = g.add_string("\{field_name}: ")
                            g = g3
                            g = g.emit_inst(
                              Lea(Reg64("rsi"), RipRel32(fn_label)),
                            )
                            g = g.emit_inst(
                              Mov(Reg64("rdx"), Imm32(field_name.length() + 2)),
                            )
                            g = g.emit_call_print()
                            // Load field value from rbp + base_offset + field_idx * 8
                            let field_offset = base_offset + field_idx * 8
                            g = g.emit_inst(
                              Mov(Reg64("rax"), StackBP64(field_offset)),
                            )
                            // Print the integer value
                            let buf_label = ".Lint_buf"
                            g = g.emit_inst(Push(Reg64("rbx")))
                            g = g.emit_inst(Push(Reg64("rcx")))
                            g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rax")))
                            g = g.emit_inst(
                              Lea(Reg64("rdi"), RipRel32(buf_label)),
                            )
                            g = g.emit_inst(Add(Reg64("rdi"), Imm32(30)))
                            g = g.emit_inst(Mov(Reg64("rcx"), Imm32(0)))
                            let (g4, digit_loop) = g.new_label()
                            let (g5, done_label) = g4.new_label()
                            g = g5
                            g = g.emit_inst(Cmp(Reg64("rbx"), Imm32(0)))
                            g = g.emit_inst(Je(done_label))
                            g = g.define_label(digit_loop)
                            g = g.emit_inst(Mov(Reg64("rax"), Reg64("rbx")))
                            g = g.emit_inst(Mov(Reg64("rdx"), Imm32(0)))
                            g = g.emit_inst(Mov(Reg64("rsi"), Imm32(10)))
                            g = g.emit_inst(Idiv(Reg64("rsi")))
                            g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rax")))
                            g = g.emit_inst(Add(Reg64("rdx"), Imm32(48)))
                            g = g.emit_inst(Mov(Reg8("sil"), Reg8("dl")))
                            g = g.emit_inst(
                              Mov(MemIndirect("rdi"), Reg8("sil")),
                            )
                            g = g.emit_inst(Dec(Reg64("rdi")))
                            g = g.emit_inst(Inc(Reg64("rcx")))
                            g = g.emit_inst(Cmp(Reg64("rbx"), Imm32(0)))
                            g = g.emit_inst(Jne(digit_loop))
                            g = g.define_label(done_label)
                            g = g.emit_inst(Cmp(Reg64("rcx"), Imm32(0)))
                            let (g6, skip_zero) = g.new_label()
                            let (g7, skip_zero_end) = g6.new_label()
                            g = g7
                            g = g.emit_inst(Jne(skip_zero))
                            g = g.emit_inst(Mov(Reg8("sil"), Imm8(48)))
                            g = g.emit_inst(
                              Mov(MemIndirect("rdi"), Reg8("sil")),
                            )
                            g = g.emit_inst(Inc(Reg64("rcx")))
                            g = g.emit_inst(Jmp(skip_zero_end))
                            g = g.define_label(skip_zero)
                            g = g.emit_inst(Inc(Reg64("rdi")))
                            g = g.define_label(skip_zero_end)
                            g = g.emit_inst(Mov(Reg64("rsi"), Reg64("rdi")))
                            g = g.emit_inst(Mov(Reg64("rdx"), Reg64("rcx")))
                            g = g.emit_call_print()
                            g = g.emit_inst(Pop(Reg64("rcx")))
                            g = g.emit_inst(Pop(Reg64("rbx")))
                            // Print comma if not last field
                            if field_idx < fields.length() - 1 {
                              let (g8, comma_label) = g.add_string(", ")
                              g = g8
                              g = g.emit_inst(
                                Lea(Reg64("rsi"), RipRel32(comma_label)),
                              )
                              g = g.emit_inst(Mov(Reg64("rdx"), Imm32(2)))
                              g = g.emit_call_print()
                            }
                            field_idx = field_idx + 1
                          }
                          // Print '}'
                          let (g9, close_label) = g.add_string("}")
                          g = g9
                          g = g.emit_inst(
                            Lea(Reg64("rsi"), RipRel32(close_label)),
                          )
                          g = g.emit_inst(Mov(Reg64("rdx"), Imm32(1)))
                          g = g.emit_call_print()
                          // Skip the normal print syscall
                          need_skip_print = true
                          g = g.emit_inst(Jmp(skip_print_label))
                        }
                        None => {
                          g = g.codegen_expr(arg)
                          let (g2, label1) = g.add_string("<struct>")
                          g = g2
                          g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(label1)))
                          g = g.emit_inst(Mov(Reg64("rdx"), Imm32(8)))
                        }
                      }
                    } else {
                      // Not an array, treat as integer
                      g = g.codegen_expr(arg)
                      let buf_label = ".Lint_buf"
                      let (g2, digit_loop) = g.new_label()
                      let (g3, done_label) = g2.new_label()
                      let (g4, skip_zero) = g3.new_label()
                      let (g5, skip_zero_end) = g4.new_label()
                      g = g5
                      g = g.emit_inst(Push(Reg64("rbx")))
                      g = g.emit_inst(Push(Reg64("rcx")))
                      g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rax")))
                      g = g.emit_inst(Lea(Reg64("rdi"), RipRel32(buf_label)))
                      g = g.emit_inst(Add(Reg64("rdi"), Imm32(30)))
                      g = g.emit_inst(Mov(Reg64("rcx"), Imm32(0)))
                      g = g.emit_inst(Cmp(Reg64("rbx"), Imm32(0)))
                      g = g.emit_inst(Je(done_label))
                      g = g.define_label(digit_loop)
                      g = g.emit_inst(Mov(Reg64("rax"), Reg64("rbx")))
                      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(0)))
                      g = g.emit_inst(Mov(Reg64("rsi"), Imm32(10)))
                      g = g.emit_inst(Idiv(Reg64("rsi")))
                      g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rax")))
                      g = g.emit_inst(Add(Reg64("rdx"), Imm32(48)))
                      g = g.emit_inst(Mov(Reg8("sil"), Reg8("dl")))
                      g = g.emit_inst(Mov(MemIndirect("rdi"), Reg8("sil")))
                      g = g.emit_inst(Dec(Reg64("rdi")))
                      g = g.emit_inst(Inc(Reg64("rcx")))
                      g = g.emit_inst(Cmp(Reg64("rbx"), Imm32(0)))
                      g = g.emit_inst(Jne(digit_loop))
                      g = g.define_label(done_label)
                      g = g.emit_inst(Cmp(Reg64("rcx"), Imm32(0)))
                      g = g.emit_inst(Jne(skip_zero))
                      g = g.emit_inst(Mov(Reg8("sil"), Imm8(48)))
                      g = g.emit_inst(Mov(MemIndirect("rdi"), Reg8("sil")))
                      g = g.emit_inst(Inc(Reg64("rcx")))
                      g = g.emit_inst(Jmp(skip_zero_end))
                      g = g.define_label(skip_zero)
                      g = g.emit_inst(Inc(Reg64("rdi")))
                      g = g.define_label(skip_zero_end)
                      g = g.emit_inst(Mov(Reg64("rsi"), Reg64("rdi")))
                      g = g.emit_inst(Mov(Reg64("rdx"), Reg64("rcx")))
                      g = g.emit_inst(Pop(Reg64("rcx")))
                      g = g.emit_inst(Pop(Reg64("rbx")))
                    }
                  Tuple(_) => {
                    g = g.codegen_expr(arg)
                    let (g2, label1) = g.add_string("<tuple>")
                    g = g2
                    g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(label1)))
                    g = g.emit_inst(Mov(Reg64("rdx"), Imm32(8)))
                  }
                  StructLit(_, _) => {
                    // Inline struct literal - just print <struct>
                    g = g.codegen_expr(arg)
                    let (g2, label1) = g.add_string("<struct>")
                    g = g2
                    g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(label1)))
                    g = g.emit_inst(Mov(Reg64("rdx"), Imm32(8)))
                  }
                  StructUpdate(base, updates) => {
                    // Inline struct update - get field names from base and print
                    let field_names = match base {
                      Ident(var_name) =>
                        match g.var_struct_fields.get(var_name) {
                          Some(fields) => fields
                          None =>
                            match g.var_types.get(var_name) {
                              Some(type_name) =>
                                match g.struct_fields.get(type_name) {
                                  Some(fields) => fields
                                  None => []
                                }
                              None => []
                            }
                        }
                      _ => []
                    }
                    let num_fields = field_names.length()
                    // Evaluate the struct update (pushes fields onto stack)
                    g = g.codegen_expr(arg)
                    // After codegen, fields are on stack: rsp points to field 0
                    // Save rsp
                    g = g.emit_inst(Push(Reg64("rbx")))
                    g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rsp")))
                    g = g.emit_inst(Add(Reg64("rbx"), Imm32(8))) // Adjust for pushed rbx
                    // Print '{'
                    let (g2, open_label) = g.add_string("{")
                    g = g2
                    g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(open_label)))
                    g = g.emit_inst(Mov(Reg64("rdx"), Imm32(1)))
                    g = g.emit_call_print()
                    // Print each field
                    let mut field_idx = 0
                    while field_idx < num_fields {
                      let field_name = field_names[field_idx]
                      // Print field name
                      let (g3, fn_label) = g.add_string("\{field_name}: ")
                      g = g3
                      g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(fn_label)))
                      g = g.emit_inst(
                        Mov(Reg64("rdx"), Imm32(field_name.length() + 2)),
                      )
                      g = g.emit_call_print()
                      // Load field value from stack: rbx + field_idx * 8
                      g = g.emit_inst(Mov(Reg64("rax"), Reg64("rbx")))
                      g = g.emit_inst(Add(Reg64("rax"), Imm32(field_idx * 8)))
                      g = g.emit_inst(Push(Reg64("rax")))
                      g = g.emit_inst(Pop(Reg64("rcx")))
                      g = g.emit_inst(Mov(Reg64("rax"), MemIndirect("rcx")))
                      // Print the integer value
                      let buf_label = ".Lint_buf"
                      g = g.emit_inst(Push(Reg64("rcx")))
                      g = g.emit_inst(Mov(Reg64("r8"), Reg64("rax")))
                      g = g.emit_inst(Lea(Reg64("rdi"), RipRel32(buf_label)))
                      g = g.emit_inst(Add(Reg64("rdi"), Imm32(30)))
                      g = g.emit_inst(Mov(Reg64("rcx"), Imm32(0)))
                      let (g4, digit_loop) = g.new_label()
                      let (g5, done_label) = g4.new_label()
                      g = g5
                      g = g.emit_inst(Cmp(Reg64("r8"), Imm32(0)))
                      g = g.emit_inst(Je(done_label))
                      g = g.define_label(digit_loop)
                      g = g.emit_inst(Mov(Reg64("rax"), Reg64("r8")))
                      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(0)))
                      g = g.emit_inst(Mov(Reg64("rsi"), Imm32(10)))
                      g = g.emit_inst(Idiv(Reg64("rsi")))
                      g = g.emit_inst(Mov(Reg64("r8"), Reg64("rax")))
                      g = g.emit_inst(Add(Reg64("rdx"), Imm32(48)))
                      g = g.emit_inst(Mov(Reg8("sil"), Reg8("dl")))
                      g = g.emit_inst(Mov(MemIndirect("rdi"), Reg8("sil")))
                      g = g.emit_inst(Dec(Reg64("rdi")))
                      g = g.emit_inst(Inc(Reg64("rcx")))
                      g = g.emit_inst(Cmp(Reg64("r8"), Imm32(0)))
                      g = g.emit_inst(Jne(digit_loop))
                      g = g.define_label(done_label)
                      g = g.emit_inst(Cmp(Reg64("rcx"), Imm32(0)))
                      let (g6, skip_zero) = g.new_label()
                      let (g7, skip_zero_end) = g6.new_label()
                      g = g7
                      g = g.emit_inst(Jne(skip_zero))
                      g = g.emit_inst(Mov(Reg8("sil"), Imm8(48)))
                      g = g.emit_inst(Mov(MemIndirect("rdi"), Reg8("sil")))
                      g = g.emit_inst(Inc(Reg64("rcx")))
                      g = g.emit_inst(Jmp(skip_zero_end))
                      g = g.define_label(skip_zero)
                      g = g.emit_inst(Inc(Reg64("rdi")))
                      g = g.define_label(skip_zero_end)
                      g = g.emit_inst(Mov(Reg64("rsi"), Reg64("rdi")))
                      g = g.emit_inst(Mov(Reg64("rdx"), Reg64("rcx")))
                      g = g.emit_call_print()
                      g = g.emit_inst(Pop(Reg64("rcx")))
                      // Print comma if not last field
                      if field_idx < num_fields - 1 {
                        let (g8, comma_label) = g.add_string(", ")
                        g = g8
                        g = g.emit_inst(
                          Lea(Reg64("rsi"), RipRel32(comma_label)),
                        )
                        g = g.emit_inst(Mov(Reg64("rdx"), Imm32(2)))
                        g = g.emit_call_print()
                      }
                      field_idx = field_idx + 1
                    }
                    // Print '}'
                    let (g9, close_label) = g.add_string("}")
                    g = g9
                    g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(close_label)))
                    g = g.emit_inst(Mov(Reg64("rdx"), Imm32(1)))
                    g = g.emit_call_print()
                    g = g.emit_inst(Pop(Reg64("rbx")))
                    // Clean up struct from stack
                    g = g.emit_inst(Add(Reg64("rsp"), Imm32(num_fields * 8)))
                    need_skip_print = true
                    g = g.emit_inst(Jmp(skip_print_label))
                  }
                  Tuple(elems) => {
                    // Tuple literal - evaluate each element and print
                    // Push callee-saved registers
                    g = g.emit_inst(Push(Reg64("rbx")))
                    g = g.emit_inst(Push(Reg64("r12")))
                    g = g.emit_inst(Push(Reg64("r13")))
                    g = g.emit_inst(Push(Reg64("r14")))
                    g = g.emit_inst(Push(Reg64("r15")))
                    // Print opening paren
                    let (g2, open_label) = g.add_string("(")
                    g = g2
                    g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(open_label)))
                    g = g.emit_inst(Mov(Reg64("rdx"), Imm32(1)))
                    g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                    g = g.emit_inst(Mov(Reg64("rdi"), Imm32(1)))
                    g = g.emit_inst(Syscall)
                    // Print each element
                    let num_elems = elems.length()
                    let mut elem_idx = 0
                    while elem_idx < num_elems {
                      // Evaluate element
                      g = g.codegen_expr(elems[elem_idx])
                      // Save rax (the element value) in r15
                      g = g.emit_inst(Mov(Reg64("r15"), Reg64("rax")))
                      // Determine type and print accordingly
                      let elem_is_float = is_float_expr(
                        elems[elem_idx],
                        g.var_is_float,
                      )
                      let elem_is_string = is_string_expr(
                        elems[elem_idx],
                        g.var_is_string,
                      )
                      let elem_is_array = is_array_expr(
                        elems[elem_idx],
                        g.var_array_len,
                      )
                      if elem_is_float {
                        // Float - print using float-to-string
                        let buf_label = ".Lflt_buf"
                        g = g.emit_inst(Sub(Reg64("rsp"), Imm32(8)))
                        g = g.emit_inst(Movsd(MemIndirect("rsp"), Xmm("xmm0")))
                        g = g.emit_inst(Lea(Reg64("rdi"), RipRel32(buf_label)))
                        g = g.emit_inst(Mov(Reg64("rax"), Imm32(0)))
                        g = g.emit_inst(Sub(Reg64("rsp"), Imm32(8)))
                        g = g.emit_inst(Movsd(MemIndirect("rsp"), Xmm("xmm0")))
                        g = g.emit_inst(Call(".Lfloat_to_string"))
                        g = g.emit_inst(Add(Reg64("rsp"), Imm32(8)))
                        g = g.emit_inst(Mov(Reg64("rsi"), Reg64("rax")))
                        // Calculate length
                        g = g.emit_inst(Push(Reg64("rax")))
                        g = g.emit_inst(Mov(Reg64("rdx"), Imm32(0)))
                        let len_loop = ".Ltuple_float_len\{g.label_counter}"
                        let len_done = ".Ltuple_float_done\{g.label_counter}"
                        g = { ..g, label_counter: g.label_counter + 2 }
                        g = g.define_label(len_loop)
                        g = g.emit_inst(Movzx(Reg64("rcx"), MemIndirect("rax")))
                        g = g.emit_inst(Cmp(Reg64("rcx"), Imm32(0)))
                        g = g.emit_inst(Je(len_done))
                        g = g.emit_inst(Inc(Reg64("rax")))
                        g = g.emit_inst(Inc(Reg64("rdx")))
                        g = g.emit_inst(Jmp(len_loop))
                        g = g.define_label(len_done)
                        g = g.emit_inst(Pop(Reg64("rax")))
                      } else if elem_is_string {
                        // String - already in rsi
                        g = g.emit_inst(Push(Reg64("r15")))
                        g = g.emit_inst(Mov(Reg64("rsi"), Reg64("r15")))
                        g = g.emit_inst(Mov(Reg64("rdx"), Imm32(0)))
                        // Calculate length
                        g = g.emit_inst(Push(Reg64("rax")))
                        g = g.emit_inst(Mov(Reg64("r15"), Reg64("rax")))
                        g = g.emit_inst(Mov(Reg64("rdx"), Imm32(0)))
                        let str_len_loop = ".Ltuple_str_len\{g.label_counter}"
                        let str_len_done = ".Ltuple_str_done\{g.label_counter}"
                        g = { ..g, label_counter: g.label_counter + 2 }
                        g = g.define_label(str_len_loop)
                        g = g.emit_inst(Movzx(Reg64("rcx"), MemIndirect("r15")))
                        g = g.emit_inst(Cmp(Reg64("rcx"), Imm32(0)))
                        g = g.emit_inst(Je(str_len_done))
                        g = g.emit_inst(Inc(Reg64("r15")))
                        g = g.emit_inst(Inc(Reg64("rdx")))
                        g = g.emit_inst(Jmp(str_len_loop))
                        g = g.define_label(str_len_done)
                        g = g.emit_inst(Pop(Reg64("rax")))
                        g = g.emit_inst(Mov(Reg64("rsi"), Reg64("rax")))
                      } else if elem_is_array {
                        // Array - print placeholder for now
                        let (g3, arr_label) = g.add_string("<array>")
                        g = g3
                        g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(arr_label)))
                        g = g.emit_inst(Mov(Reg64("rdx"), Imm32(7)))
                      } else {
                        // Integer or other - print using integer-to-string
                        g = g.emit_inst(Push(Reg64("r15")))
                        let buf_label = ".Lint_buf"
                        g = g.emit_inst(Mov(Reg64("rbx"), Reg64("r15")))
                        g = g.emit_inst(Lea(Reg64("rdi"), RipRel32(buf_label)))
                        g = g.emit_inst(Add(Reg64("rdi"), Imm32(30)))
                        g = g.emit_inst(Mov(Reg64("rcx"), Imm32(0)))
                        let (g3, digit_loop) = g.new_label()
                        let (g4, done_label) = g3.new_label()
                        g = g4
                        g = g.emit_inst(Cmp(Reg64("rbx"), Imm32(0)))
                        g = g.emit_inst(Je(done_label))
                        g = g.define_label(digit_loop)
                        g = g.emit_inst(Mov(Reg64("rax"), Reg64("rbx")))
                        g = g.emit_inst(Mov(Reg64("rdx"), Imm32(0)))
                        g = g.emit_inst(Mov(Reg64("rsi"), Imm32(10)))
                        g = g.emit_inst(Idiv(Reg64("rsi")))
                        g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rax")))
                        g = g.emit_inst(Add(Reg64("rdx"), Imm32(48)))
                        g = g.emit_inst(Mov(Reg8("sil"), Reg8("dl")))
                        g = g.emit_inst(Mov(MemIndirect("rdi"), Reg8("sil")))
                        g = g.emit_inst(Dec(Reg64("rdi")))
                        g = g.emit_inst(Inc(Reg64("rcx")))
                        g = g.emit_inst(Cmp(Reg64("rbx"), Imm32(0)))
                        g = g.emit_inst(Jne(digit_loop))
                        g = g.define_label(done_label)
                        g = g.emit_inst(Inc(Reg64("rdi")))
                        g = g.emit_inst(Mov(Reg64("rsi"), Reg64("rdi")))
                        g = g.emit_inst(Mov(Reg64("rdx"), Reg64("rcx")))
                        g = g.emit_inst(Pop(Reg64("rax")))
                      }
                      // Print the element
                      g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                      g = g.emit_inst(Mov(Reg64("rdi"), Imm32(1)))
                      g = g.emit_inst(Syscall)
                      // Print comma and space if not last
                      if elem_idx < num_elems - 1 {
                        let (g5, comma_label) = g.add_string(", ")
                        g = g5
                        g = g.emit_inst(
                          Lea(Reg64("rsi"), RipRel32(comma_label)),
                        )
                        g = g.emit_inst(Mov(Reg64("rdx"), Imm32(2)))
                        g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                        g = g.emit_inst(Mov(Reg64("rdi"), Imm32(1)))
                        g = g.emit_inst(Syscall)
                      }
                      elem_idx = elem_idx + 1
                    }
                    // Print closing paren
                    let (g6, close_label) = g.add_string(")")
                    g = g6
                    g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(close_label)))
                    g = g.emit_inst(Mov(Reg64("rdx"), Imm32(1)))
                    g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                    g = g.emit_inst(Mov(Reg64("rdi"), Imm32(1)))
                    g = g.emit_inst(Syscall)
                    // Restore callee-saved registers
                    g = g.emit_inst(Pop(Reg64("r15")))
                    g = g.emit_inst(Pop(Reg64("r14")))
                    g = g.emit_inst(Pop(Reg64("r13")))
                    g = g.emit_inst(Pop(Reg64("r12")))
                    g = g.emit_inst(Pop(Reg64("rbx")))
                    need_skip_print = true
                    g = g.emit_inst(Jmp(skip_print_label))
                  }
                  MapLit(entries) => {
                    // Map literal - print a placeholder
                    g = g.codegen_expr(arg)
                    let (g2, label1) = g.add_string("<map>")
                    g = g2
                    g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(label1)))
                    g = g.emit_inst(Mov(Reg64("rdx"), Imm32(5)))
                  }
                  CallExpr(Ident(fname), inner_args) =>
                    if fname == "int_to_string" {
                      g = g.codegen_expr(arg)
                      g = g.emit_inst(Mov(Reg64("rsi"), Reg64("rax")))
                    } else if fname == "float_to_string" ||
                      fname == "string_concat" {
                      g = g.codegen_expr(arg)
                      g = g.emit_inst(Mov(Reg64("rsi"), Reg64("rax")))
                    } else if fname == "string_to_float" {
                      g = g.codegen_expr(arg)
                      let (g2, label) = g.add_string("<float>")
                      g = g2
                      g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(label)))
                      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(7)))
                    } else if fname == "input" {
                      g = g.codegen_expr(arg)
                      g = g.emit_inst(Mov(Reg64("rsi"), Reg64("rax")))
                    } else {
                      g = g.codegen_expr(arg)
                      let buf_label = ".Lint_buf"
                      let (g2, digit_loop) = g.new_label()
                      let (g3, done_label) = g2.new_label()
                      let (g4, skip_zero) = g3.new_label()
                      let (g5, skip_zero_end) = g4.new_label()
                      g = g5
                      g = g.emit_inst(Push(Reg64("rbx")))
                      g = g.emit_inst(Push(Reg64("rcx")))
                      g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rax")))
                      g = g.emit_inst(Lea(Reg64("rdi"), RipRel32(buf_label)))
                      g = g.emit_inst(Add(Reg64("rdi"), Imm32(30)))
                      g = g.emit_inst(Mov(Reg64("rcx"), Imm32(0)))
                      g = g.emit_inst(Cmp(Reg64("rbx"), Imm32(0)))
                      g = g.emit_inst(Je(done_label))
                      g = g.define_label(digit_loop)
                      g = g.emit_inst(Mov(Reg64("rax"), Reg64("rbx")))
                      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(0)))
                      g = g.emit_inst(Mov(Reg64("rsi"), Imm32(10)))
                      g = g.emit_inst(Idiv(Reg64("rsi")))
                      g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rax")))
                      g = g.emit_inst(Add(Reg64("rdx"), Imm32(48)))
                      g = g.emit_inst(Mov(Reg8("sil"), Reg8("dl")))
                      g = g.emit_inst(Mov(MemIndirect("rdi"), Reg8("sil")))
                      g = g.emit_inst(Dec(Reg64("rdi")))
                      g = g.emit_inst(Inc(Reg64("rcx")))
                      g = g.emit_inst(Cmp(Reg64("rbx"), Imm32(0)))
                      g = g.emit_inst(Jne(digit_loop))
                      g = g.define_label(done_label)
                      g = g.emit_inst(Cmp(Reg64("rcx"), Imm32(0)))
                      g = g.emit_inst(Jne(skip_zero))
                      g = g.emit_inst(Mov(Reg8("sil"), Imm8(48)))
                      g = g.emit_inst(Mov(MemIndirect("rdi"), Reg8("sil")))
                      g = g.emit_inst(Inc(Reg64("rcx")))
                      g = g.emit_inst(Jmp(skip_zero_end))
                      g = g.define_label(skip_zero)
                      g = g.emit_inst(Inc(Reg64("rdi")))
                      g = g.define_label(skip_zero_end)
                      g = g.emit_inst(Mov(Reg64("rsi"), Reg64("rdi")))
                      g = g.emit_inst(Mov(Reg64("rdx"), Reg64("rcx")))
                      g = g.emit_inst(Pop(Reg64("rcx")))
                      g = g.emit_inst(Pop(Reg64("rbx")))
                    }
                  _ => {
                    let is_arr = is_array_expr(arg, g.var_array_len)
                    let is_float = is_float_expr(arg, g.var_is_float)
                    let is_string = is_string_expr(arg, g.var_is_string)
                    let is_bool = is_bool_expr(arg, g.var_is_bool)
                    let is_int = is_int_expr(arg, g.var_is_float, g.var_is_map)
                    let is_map = is_map_expr(arg, g.var_is_map)
                    let is_tuple_float_field = match arg {
                      FieldExpr(Ident(var_name), field) => {
                        let idx = if field.length() > 0 {
                          let c = field[0]
                          if c >= '0' && c <= '9' {
                            c.to_int() - 48
                          } else {
                            0
                          }
                        } else {
                          0
                        }
                        match g.var_tuple_field_types.get(var_name) {
                          Some(types) => idx < types.length() && types[idx]
                          None => false
                        }
                      }
                      _ => false
                    }
                    if is_arr {
                      g = g.codegen_expr(arg)
                      g = g.emit_inst(Push(Reg64("rbx")))
                      g = g.emit_inst(Push(Reg64("r12")))
                      g = g.emit_inst(Push(Reg64("r13")))
                      g = g.emit_inst(Push(Reg64("r14")))
                      g = g.emit_inst(Push(Reg64("r15")))
                      g = g.emit_inst(Mov(Reg64("r12"), Reg64("rax")))
                      g = g.emit_inst(Mov(Reg64("r13"), MemIndirect("rax")))
                      g = g.emit_inst(Mov(Reg64("r14"), Imm32(0)))
                      let (g2, open_label) = g.add_string("[")
                      g = g2
                      g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(open_label)))
                      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(1)))
                      g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                      g = g.emit_inst(Mov(Reg64("rdi"), Imm32(1)))
                      g = g.emit_inst(Syscall)
                      let arr_loop = ".Larr_print_loop\{g.label_counter}"
                      let arr_done = ".Larr_print_done\{g.label_counter}"
                      let elem_print = ".Larr_elem_print\{g.label_counter + 1}"
                      g = { ..g, label_counter: g.label_counter + 2 }
                      g = g.define_label(arr_loop)
                      g = g.emit_inst(Mov(Reg64("rax"), Reg64("r14")))
                      g = g.emit_inst(Cmp(Reg64("rax"), Reg64("r13")))
                      g = g.emit_inst(Jae(arr_done))
                      g = g.emit_inst(Cmp(Reg64("r14"), Imm32(0)))
                      g = g.emit_inst(Je(elem_print))
                      let (g3, comma_label) = g.add_string(", ")
                      g = g3
                      g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(comma_label)))
                      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(2)))
                      g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                      g = g.emit_inst(Mov(Reg64("rdi"), Imm32(1)))
                      g = g.emit_inst(Syscall)
                      g = g.define_label(elem_print)
                      g = g.emit_inst(Mov(Reg64("rax"), Reg64("r14")))
                      g = g.emit_inst(Mov(Reg64("rcx"), Imm32(8)))
                      g = g.emit_inst(Imul(Reg64("rax"), Reg64("rcx")))
                      g = g.emit_inst(Mov(Reg64("rbx"), Reg64("r12")))
                      g = g.emit_inst(Add(Reg64("rbx"), Reg64("rax")))
                      g = g.emit_inst(Add(Reg64("rbx"), Imm32(8)))
                      g = g.emit_inst(Mov(Reg64("rax"), MemIndirect("rbx")))
                      g = g.emit_inst(Mov(Reg64("r15"), Reg64("rax")))
                      let buf_label = ".Lint_buf"
                      let (g4, digit_loop) = g.new_label()
                      let (g5, done_label) = g4.new_label()
                      let (g6, skip_zero) = g5.new_label()
                      let (g7, skip_zero_end) = g6.new_label()
                      g = g7
                      g = g.emit_inst(Mov(Reg64("rbx"), Reg64("r15")))
                      g = g.emit_inst(Lea(Reg64("rdi"), RipRel32(buf_label)))
                      g = g.emit_inst(Add(Reg64("rdi"), Imm32(30)))
                      g = g.emit_inst(Mov(Reg64("rcx"), Imm32(0)))
                      g = g.emit_inst(Cmp(Reg64("rbx"), Imm32(0)))
                      g = g.emit_inst(Je(done_label))
                      g = g.define_label(digit_loop)
                      g = g.emit_inst(Mov(Reg64("rax"), Reg64("rbx")))
                      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(0)))
                      g = g.emit_inst(Mov(Reg64("rsi"), Imm32(10)))
                      g = g.emit_inst(Idiv(Reg64("rsi")))
                      g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rax")))
                      g = g.emit_inst(Add(Reg64("rdx"), Imm32(48)))
                      g = g.emit_inst(Mov(Reg8("sil"), Reg8("dl")))
                      g = g.emit_inst(Mov(MemIndirect("rdi"), Reg8("sil")))
                      g = g.emit_inst(Dec(Reg64("rdi")))
                      g = g.emit_inst(Inc(Reg64("rcx")))
                      g = g.emit_inst(Cmp(Reg64("rbx"), Imm32(0)))
                      g = g.emit_inst(Jne(digit_loop))
                      g = g.define_label(done_label)
                      g = g.emit_inst(Cmp(Reg64("rcx"), Imm32(0)))
                      g = g.emit_inst(Jne(skip_zero))
                      g = g.emit_inst(Mov(Reg8("sil"), Imm8(48)))
                      g = g.emit_inst(Mov(MemIndirect("rdi"), Reg8("sil")))
                      g = g.emit_inst(Inc(Reg64("rcx")))
                      g = g.emit_inst(Jmp(skip_zero_end))
                      g = g.define_label(skip_zero)
                      g = g.emit_inst(Inc(Reg64("rdi")))
                      g = g.define_label(skip_zero_end)
                      g = g.emit_inst(Mov(Reg64("rsi"), Reg64("rdi")))
                      g = g.emit_inst(Mov(Reg64("rdx"), Reg64("rcx")))
                      g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                      g = g.emit_inst(Mov(Reg64("rdi"), Imm32(1)))
                      g = g.emit_inst(Syscall)
                      g = g.emit_inst(Inc(Reg64("r14")))
                      g = g.emit_inst(Jmp(arr_loop))
                      g = g.define_label(arr_done)
                      let (g8, close_label) = g.add_string("]")
                      g = g8
                      g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(close_label)))
                      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(1)))
                      g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                      g = g.emit_inst(Mov(Reg64("rdi"), Imm32(1)))
                      g = g.emit_inst(Syscall)
                      g = g.emit_inst(Pop(Reg64("r15")))
                      g = g.emit_inst(Pop(Reg64("r14")))
                      g = g.emit_inst(Pop(Reg64("r13")))
                      g = g.emit_inst(Pop(Reg64("r12")))
                      g = g.emit_inst(Pop(Reg64("rbx")))
                      need_skip_print = true
                      g = g.emit_inst(Jmp(skip_print_label))
                    } else if is_string {
                      g = g.codegen_expr(arg)
                      g = g.emit_inst(Mov(Reg64("rsi"), Reg64("rax")))
                      let (g2, len_loop) = g.new_label()
                      let (g3, len_done) = g2.new_label()
                      g = g3
                      g = g.emit_inst(Push(Reg64("rax")))
                      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(0)))
                      g = g.define_label(len_loop)
                      g = g.emit_inst(Movzx(Reg64("rcx"), MemIndirect("rax")))
                      g = g.emit_inst(Cmp(Reg64("rcx"), Imm32(0)))
                      g = g.emit_inst(Je(len_done))
                      g = g.emit_inst(Inc(Reg64("rax")))
                      g = g.emit_inst(Inc(Reg64("rdx")))
                      g = g.emit_inst(Jmp(len_loop))
                      g = g.define_label(len_done)
                      g = g.emit_inst(Pop(Reg64("rax")))
                      g = g.emit_inst(Mov(Reg64("rsi"), Reg64("rax")))
                    } else if is_float || is_tuple_float_field {
                      g = g.codegen_expr(arg)
                      let flt_buf = ".Lflt_buf"
                      g = g.emit_inst(Push(Reg64("rbx")))
                      g = g.emit_inst(Push(Reg64("rcx")))
                      g = g.emit_inst(Push(Reg64("r8")))
                      g = g.emit_inst(Push(Reg64("r9")))
                      g = g.emit_inst(Cvttsd2si(Reg64("rax"), Xmm("xmm0")))
                      g = g.emit_inst(Mov(Reg64("r9"), Reg64("rax")))
                      g = g.emit_inst(Lea(Reg64("rbx"), RipRel32(flt_buf)))
                      g = g.emit_inst(Add(Reg64("rbx"), Imm32(40)))
                      g = g.emit_inst(Mov(Reg64("rcx"), Imm32(0)))
                      let (g2, digit_loop) = g.new_label()
                      let (g3, skip_zero) = g2.new_label()
                      let (g4, skip_zero_end) = g3.new_label()
                      g = g4
                      g = g.emit_inst(Cmp(Reg64("r9"), Imm32(0)))
                      g = g.emit_inst(Jne(digit_loop))
                      g = g.emit_inst(Mov(Reg8("al"), Imm8(48)))
                      g = g.emit_inst(Mov(MemIndirect("rbx"), Reg8("al")))
                      g = g.emit_inst(Dec(Reg64("rbx")))
                      g = g.emit_inst(Inc(Reg64("rcx")))
                      g = g.emit_inst(Jmp(skip_zero_end))
                      g = g.define_label(digit_loop)
                      g = g.emit_inst(Mov(Reg64("rax"), Reg64("r9")))
                      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(0)))
                      g = g.emit_inst(Mov(Reg64("r8"), Imm32(10)))
                      g = g.emit_inst(Idiv(Reg64("r8")))
                      g = g.emit_inst(Mov(Reg64("r9"), Reg64("rax")))
                      g = g.emit_inst(Add(Reg64("rdx"), Imm32(48)))
                      g = g.emit_inst(Mov(MemIndirect("rbx"), Reg8("dl")))
                      g = g.emit_inst(Dec(Reg64("rbx")))
                      g = g.emit_inst(Inc(Reg64("rcx")))
                      g = g.emit_inst(Cmp(Reg64("r9"), Imm32(0)))
                      g = g.emit_inst(Jne(digit_loop))
                      g = g.define_label(skip_zero)
                      g = g.emit_inst(Inc(Reg64("rbx")))
                      g = g.define_label(skip_zero_end)
                      g = g.emit_inst(Mov(Reg64("rsi"), Reg64("rbx")))
                      g = g.emit_inst(Mov(Reg64("r8"), Reg64("rcx")))
                      g = g.emit_inst(Add(Reg64("rbx"), Reg64("rcx")))
                      g = g.emit_inst(Mov(Reg8("al"), Imm8(46)))
                      g = g.emit_inst(Mov(MemIndirect("rbx"), Reg8("al")))
                      g = g.emit_inst(Inc(Reg64("rbx")))
                      g = g.emit_inst(Mov(Reg8("al"), Imm8(48)))
                      g = g.emit_inst(Mov(MemIndirect("rbx"), Reg8("al")))
                      g = g.emit_inst(Mov(Reg64("rdx"), Reg64("r8")))
                      g = g.emit_inst(Add(Reg64("rdx"), Imm32(2)))
                      g = g.emit_inst(Pop(Reg64("r9")))
                      g = g.emit_inst(Pop(Reg64("r8")))
                      g = g.emit_inst(Pop(Reg64("rcx")))
                      g = g.emit_inst(Pop(Reg64("rbx")))
                    } else if is_bool {
                      let (g2, true_label) = g.new_label()
                      let (g3, end_label) = g2.new_label()
                      g = g3
                      g = g.codegen_expr(arg)
                      g = g.emit_inst(Cmp(Reg64("rax"), Imm32(0)))
                      g = g.emit_inst(Je(true_label))
                      let (g4, s_true) = g.add_string("true")
                      g = g4
                      g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(s_true)))
                      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(4)))
                      g = g.emit_inst(Jmp(end_label))
                      g = g.define_label(true_label)
                      let (g5, s_false) = g.add_string("false")
                      g = g5
                      g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(s_false)))
                      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(5)))
                      g = g.define_label(end_label)
                    } else if is_int {
                      g = g.codegen_expr(arg)
                      let buf_label = ".Lint_buf"
                      let (g2, digit_loop) = g.new_label()
                      let (g3, done_label) = g2.new_label()
                      let (g4, skip_zero) = g3.new_label()
                      let (g5, skip_zero_end) = g4.new_label()
                      g = g5
                      g = g.emit_inst(Push(Reg64("rbx")))
                      g = g.emit_inst(Push(Reg64("rcx")))
                      g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rax")))
                      g = g.emit_inst(Lea(Reg64("rdi"), RipRel32(buf_label)))
                      g = g.emit_inst(Add(Reg64("rdi"), Imm32(30)))
                      g = g.emit_inst(Mov(Reg64("rcx"), Imm32(0)))
                      g = g.emit_inst(Cmp(Reg64("rbx"), Imm32(0)))
                      g = g.emit_inst(Je(done_label))
                      g = g.define_label(digit_loop)
                      g = g.emit_inst(Mov(Reg64("rax"), Reg64("rbx")))
                      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(0)))
                      g = g.emit_inst(Mov(Reg64("rsi"), Imm32(10)))
                      g = g.emit_inst(Idiv(Reg64("rsi")))
                      g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rax")))
                      g = g.emit_inst(Add(Reg64("rdx"), Imm32(48)))
                      g = g.emit_inst(Mov(Reg8("sil"), Reg8("dl")))
                      g = g.emit_inst(Mov(MemIndirect("rdi"), Reg8("sil")))
                      g = g.emit_inst(Dec(Reg64("rdi")))
                      g = g.emit_inst(Inc(Reg64("rcx")))
                      g = g.emit_inst(Cmp(Reg64("rbx"), Imm32(0)))
                      g = g.emit_inst(Jne(digit_loop))
                      g = g.define_label(done_label)
                      g = g.emit_inst(Cmp(Reg64("rcx"), Imm32(0)))
                      g = g.emit_inst(Jne(skip_zero))
                      g = g.emit_inst(Mov(Reg8("sil"), Imm8(48)))
                      g = g.emit_inst(Mov(MemIndirect("rdi"), Reg8("sil")))
                      g = g.emit_inst(Inc(Reg64("rcx")))
                      g = g.emit_inst(Jmp(skip_zero_end))
                      g = g.define_label(skip_zero)
                      g = g.emit_inst(Inc(Reg64("rdi")))
                      g = g.define_label(skip_zero_end)
                      g = g.emit_inst(Mov(Reg64("rsi"), Reg64("rdi")))
                      g = g.emit_inst(Mov(Reg64("rdx"), Reg64("rcx")))
                      g = g.emit_inst(Pop(Reg64("rcx")))
                      g = g.emit_inst(Pop(Reg64("rbx")))
                    } else if is_map {
                      g = g.codegen_expr(arg)
                      let (g2, map_label) = g.add_string("<map>")
                      g = g2
                      g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(map_label)))
                      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(5)))
                    } else {
                      g = g.codegen_expr(arg)
                      g = g.emit_inst(Mov(Reg64("rsi"), Reg64("rax")))
                    }
                  }
                }
                g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                g = g.emit_inst(Mov(Reg64("rdi"), Imm32(1)))
                g = g.emit_inst(Syscall)
                g = g.define_label(skip_print_label)
                arg_idx = arg_idx + 1
              }
              if is_println {
                let (g2, label) = g.add_string("\n")
                g = g2
                g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(label)))
                g = g.emit_inst(Mov(Reg64("rdx"), Imm32(1)))
                g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                g = g.emit_inst(Mov(Reg64("rdi"), Imm32(1)))
                g = g.emit_inst(Syscall)
              }
              g = g.emit_inst(Mov(Reg64("rax"), Imm32(0)))
              g
            }
            "char_to_int" =>
              if args.length() == 1 {
                self.codegen_expr(args[0])
              } else {
                self.emit_inst(Mov(Reg64("rax"), Imm32(0)))
              }
            "int_to_char" =>
              if args.length() == 1 {
                self.codegen_expr(args[0])
              } else {
                self.emit_inst(Mov(Reg64("rax"), Imm32(0)))
              }
            "input" => {
              let mut g = self
              let label = ".Linput_buf"
              g = g.emit_inst(Mov(Reg64("rax"), Imm32(0)))
              g = g.emit_inst(Mov(Reg64("rdi"), Imm32(0)))
              g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(label)))
              g = g.emit_inst(Mov(Reg64("rdx"), Imm32(255)))
              g = g.emit_inst(Syscall)
              g = g.emit_inst(Mov(Reg64("rdx"), Reg64("rax")))
              g = g.emit_inst(Lea(Reg64("rax"), RipRel32(label)))
              g
            }
            "int_to_string" =>
              if args.length() == 1 {
                let mut g = self
                g = g.codegen_expr(args[0])
                let buf_label = ".Lint_buf"
                let (g2, digit_loop) = g.new_label()
                let (g3, done_label) = g2.new_label()
                let (g4, skip_zero) = g3.new_label()
                let (g5, skip_zero_end) = g4.new_label()
                g = g5
                g = g.emit_inst(Push(Reg64("rbx")))
                g = g.emit_inst(Push(Reg64("rcx")))
                g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rax")))
                g = g.emit_inst(Lea(Reg64("rdi"), RipRel32(buf_label)))
                g = g.emit_inst(Add(Reg64("rdi"), Imm32(30)))
                g = g.emit_inst(Mov(Reg64("rcx"), Imm32(0)))
                g = g.emit_inst(Cmp(Reg64("rbx"), Imm32(0)))
                g = g.emit_inst(Je(done_label))
                g = g.define_label(digit_loop)
                g = g.emit_inst(Mov(Reg64("rax"), Reg64("rbx")))
                g = g.emit_inst(Mov(Reg64("rdx"), Imm32(0)))
                g = g.emit_inst(Mov(Reg64("rsi"), Imm32(10)))
                g = g.emit_inst(Idiv(Reg64("rsi")))
                g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rax")))
                g = g.emit_inst(Add(Reg64("rdx"), Imm32(48)))
                g = g.emit_inst(Mov(Reg8("sil"), Reg8("dl")))
                g = g.emit_inst(Mov(MemIndirect("rdi"), Reg8("sil")))
                g = g.emit_inst(Dec(Reg64("rdi")))
                g = g.emit_inst(Inc(Reg64("rcx")))
                g = g.emit_inst(Cmp(Reg64("rbx"), Imm32(0)))
                g = g.emit_inst(Jne(digit_loop))
                g = g.define_label(done_label)
                g = g.emit_inst(Cmp(Reg64("rcx"), Imm32(0)))
                g = g.emit_inst(Jne(skip_zero))
                g = g.emit_inst(Mov(Reg8("sil"), Imm8(48)))
                g = g.emit_inst(Mov(MemIndirect("rdi"), Reg8("sil")))
                g = g.emit_inst(Inc(Reg64("rcx")))
                g = g.emit_inst(Jmp(skip_zero_end))
                g = g.define_label(skip_zero)
                g = g.emit_inst(Inc(Reg64("rdi")))
                g = g.define_label(skip_zero_end)
                g = g.emit_inst(Mov(Reg64("rax"), Reg64("rdi")))
                g = g.emit_inst(Mov(Reg64("rdx"), Reg64("rcx")))
                g = g.emit_inst(Pop(Reg64("rcx")))
                g = g.emit_inst(Pop(Reg64("rbx")))
                g
              } else {
                self.emit_inst(Mov(Reg64("rax"), Imm32(0)))
              }
            "string_to_int" =>
              if args.length() == 1 {
                let mut g = self
                g = g.codegen_expr(args[0])
                let (g2, loop_label) = g.new_label()
                let (g3, done_label) = g2.new_label()
                g = g3
                g = g.emit_inst(Push(Reg64("rbx")))
                g = g.emit_inst(Push(Reg64("rcx")))
                g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rax")))
                g = g.emit_inst(Mov(Reg64("rax"), Imm32(0)))
                g = g.emit_inst(Mov(Reg64("rcx"), Imm32(10)))
                g = g.define_label(loop_label)
                g = g.emit_inst(Movzx(Reg64("rdx"), MemIndirect("rbx")))
                g = g.emit_inst(Cmp(Reg64("rdx"), Imm32(48)))
                g = g.emit_inst(Jb(done_label))
                g = g.emit_inst(Cmp(Reg64("rdx"), Imm32(57)))
                g = g.emit_inst(Ja(done_label))
                g = g.emit_inst(Imul(Reg64("rax"), Reg64("rcx")))
                g = g.emit_inst(Sub(Reg64("rdx"), Imm32(48)))
                g = g.emit_inst(Add(Reg64("rax"), Reg64("rdx")))
                g = g.emit_inst(Inc(Reg64("rbx")))
                g = g.emit_inst(Jmp(loop_label))
                g = g.define_label(done_label)
                g = g.emit_inst(Pop(Reg64("rcx")))
                g = g.emit_inst(Pop(Reg64("rbx")))
                g
              } else {
                self.emit_inst(Mov(Reg64("rax"), Imm32(0)))
              }
            "string_to_float" =>
              if args.length() == 1 {
                let mut g = self
                g = g.codegen_expr(args[0])
                g = g.emit_inst(Push(Reg64("rbx")))
                g = g.emit_inst(Push(Reg64("rcx")))
                g = g.emit_inst(Push(Reg64("rdi")))
                g = g.emit_inst(Push(Reg64("r8")))
                g = g.emit_inst(Push(Reg64("r9")))
                g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rax")))
                g = g.emit_inst(Mov(Reg64("r8"), Imm32(0)))
                g = g.emit_inst(Cvtsi2sd(Xmm("xmm0"), Reg64("r8")))
                let (g2, digit_loop) = g.new_label()
                let (g3, found_dot) = g2.new_label()
                let (g4, frac_loop) = g3.new_label()
                let (g5, done) = g4.new_label()
                g = g5
                g = g.define_label(digit_loop)
                g = g.emit_inst(Movzx(Reg64("rcx"), MemIndirect("rbx")))
                g = g.emit_inst(Cmp(Reg64("rcx"), Imm32(46)))
                g = g.emit_inst(Je(found_dot))
                g = g.emit_inst(Cmp(Reg64("rcx"), Imm32(48)))
                g = g.emit_inst(Jb(done))
                g = g.emit_inst(Cmp(Reg64("rcx"), Imm32(57)))
                g = g.emit_inst(Ja(done))
                g = g.emit_inst(Imul(Reg64("r8"), Imm32(10)))
                g = g.emit_inst(Sub(Reg64("rcx"), Imm32(48)))
                g = g.emit_inst(Add(Reg64("r8"), Reg64("rcx")))
                g = g.emit_inst(Inc(Reg64("rbx")))
                g = g.emit_inst(Jmp(digit_loop))
                g = g.define_label(found_dot)
                g = g.emit_inst(Inc(Reg64("rbx")))
                g = g.emit_inst(Mov(Reg64("r9"), Imm32(0)))
                g = g.define_label(frac_loop)
                g = g.emit_inst(Movzx(Reg64("rcx"), MemIndirect("rbx")))
                g = g.emit_inst(Cmp(Reg64("rcx"), Imm32(48)))
                g = g.emit_inst(Jb(done))
                g = g.emit_inst(Cmp(Reg64("rcx"), Imm32(57)))
                g = g.emit_inst(Ja(done))
                g = g.emit_inst(Cvtsi2sd(Xmm("xmm1"), Reg64("r8")))
                g = g.emit_inst(Mov(Reg64("r8"), Imm32(10)))
                g = g.emit_inst(Cvtsi2sd(Xmm("xmm2"), Reg64("r8")))
                g = g.emit_inst(Divsd(Xmm("xmm1"), Xmm("xmm2")))
                g = g.emit_inst(Addsd(Xmm("xmm0"), Xmm("xmm1")))
                g = g.emit_inst(Sub(Reg64("rcx"), Imm32(48)))
                g = g.emit_inst(Cvtsi2sd(Xmm("xmm1"), Reg64("rcx")))
                g = g.emit_inst(Divsd(Xmm("xmm1"), Xmm("xmm2")))
                g = g.emit_inst(Addsd(Xmm("xmm0"), Xmm("xmm1")))
                g = g.emit_inst(Inc(Reg64("rbx")))
                g = g.emit_inst(Inc(Reg64("r9")))
                g = g.emit_inst(Jmp(frac_loop))
                g = g.define_label(done)
                g = g.emit_inst(Pop(Reg64("r9")))
                g = g.emit_inst(Pop(Reg64("r8")))
                g = g.emit_inst(Pop(Reg64("rdi")))
                g = g.emit_inst(Pop(Reg64("rcx")))
                g = g.emit_inst(Pop(Reg64("rbx")))
                g
              } else {
                self.emit_inst(Cvtsi2sd(Xmm("xmm0"), Imm32(0)))
              }
            "string_concat" =>
              if args.length() == 2 {
                let mut g = self
                g = g.codegen_expr(args[0])
                g = g.emit_inst(Push(Reg64("rax")))
                g = g.codegen_expr(args[1])
                g = g.emit_inst(Mov(Reg64("rdi"), Reg64("rax")))
                g = g.emit_inst(Pop(Reg64("rsi")))
                let (g2, copy1_loop) = g.new_label()
                let (g3, copy1_done) = g2.new_label()
                let (g4, copy2_loop) = g3.new_label()
                let (g5, copy2_done) = g4.new_label()
                g = g5
                g = g.emit_inst(Push(Reg64("rbx")))
                g = g.emit_inst(Push(Reg64("rcx")))
                let buf_label = ".Lstrcat_buf"
                g = g.emit_inst(Lea(Reg64("rax"), RipRel32(buf_label)))
                g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rax")))
                g = g.emit_inst(Mov(Reg64("rcx"), Imm32(0)))
                g = g.define_label(copy1_loop)
                g = g.emit_inst(Movzx(Reg64("rax"), MemIndirect("rsi")))
                g = g.emit_inst(Test(Reg64("rax"), Reg64("rax")))
                g = g.emit_inst(Jz(copy1_done))
                g = g.emit_inst(Mov(MemIndirect("rbx"), Reg8("al")))
                g = g.emit_inst(Inc(Reg64("rbx")))
                g = g.emit_inst(Inc(Reg64("rsi")))
                g = g.emit_inst(Inc(Reg64("rcx")))
                g = g.emit_inst(Jmp(copy1_loop))
                g = g.define_label(copy1_done)
                g = g.define_label(copy2_loop)
                g = g.emit_inst(Movzx(Reg64("rax"), MemIndirect("rdi")))
                g = g.emit_inst(Test(Reg64("rax"), Reg64("rax")))
                g = g.emit_inst(Jz(copy2_done))
                g = g.emit_inst(Mov(MemIndirect("rbx"), Reg8("al")))
                g = g.emit_inst(Inc(Reg64("rbx")))
                g = g.emit_inst(Inc(Reg64("rdi")))
                g = g.emit_inst(Inc(Reg64("rcx")))
                g = g.emit_inst(Jmp(copy2_loop))
                g = g.define_label(copy2_done)
                g = g.emit_inst(Mov(Reg8("al"), Imm8(0)))
                g = g.emit_inst(Mov(MemIndirect("rbx"), Reg8("al")))
                g = g.emit_inst(Lea(Reg64("rax"), RipRel32(buf_label)))
                g = g.emit_inst(Mov(Reg64("rdx"), Reg64("rcx")))
                g = g.emit_inst(Pop(Reg64("rcx")))
                g = g.emit_inst(Pop(Reg64("rbx")))
                g
              } else {
                self.emit_inst(Mov(Reg64("rax"), Imm32(0)))
              }
            "float_to_string" =>
              if args.length() == 1 {
                let mut g = self
                g = g.codegen_expr(args[0])
                g = g.emit_inst(Push(Reg64("rbx")))
                g = g.emit_inst(Push(Reg64("rcx")))
                g = g.emit_inst(Push(Reg64("rsi")))
                g = g.emit_inst(Push(Reg64("rdi")))
                // xmm0 has the float - convert to int
                g = g.emit_inst(Cvttsd2si(Reg64("rax"), Xmm("xmm0")))
                g = g.emit_inst(Mov(Reg64("r8"), Reg64("rax")))
                // Output to buffer (working backwards from end)
                let flt_buf = ".Lflt_buf"
                g = g.emit_inst(Lea(Reg64("rdi"), RipRel32(flt_buf)))
                g = g.emit_inst(Add(Reg64("rdi"), Imm32(40)))
                g = g.emit_inst(Mov(Reg64("rcx"), Imm32(0)))
                // Extract digits (in reverse order)
                let (g2, zero_case) = g.new_label()
                let (g3, done_digits) = g2.new_label()
                g = g.emit_inst(Cmp(Reg64("r8"), Imm32(0)))
                g = g.emit_inst(Je(zero_case))
                g = g.define_label(done_digits)
                g = g.emit_inst(Mov(Reg64("rax"), Reg64("r8")))
                g = g.emit_inst(Mov(Reg64("rbx"), Imm32(0)))
                g = g.emit_inst(Mov(Reg64("rdx"), Imm32(0)))
                g = g.emit_inst(Mov(Reg64("rsi"), Imm32(10)))
                g = g.emit_inst(Idiv(Reg64("rsi")))
                g = g.emit_inst(Mov(Reg64("r8"), Reg64("rax")))
                g = g.emit_inst(Add(Reg64("rdx"), Imm32(48)))
                g = g.emit_inst(Mov(MemIndirect("rdi"), Reg8("dl")))
                g = g.emit_inst(Inc(Reg64("rdi")))
                g = g.emit_inst(Inc(Reg64("rcx")))
                g = g.emit_inst(Cmp(Reg64("r8"), Imm32(0)))
                g = g.emit_inst(Jne(done_digits))
                g = g.define_label(zero_case)
                // Add ".x" suffix - force 2 bytes
                g = g.emit_inst(Mov(Reg8("al"), Imm8(46))) // '.'
                g = g.emit_inst(Mov(MemIndirect("rdi"), Reg8("al")))
                g = g.emit_inst(Inc(Reg64("rdi")))
                g = g.emit_inst(Inc(Reg64("rcx")))
                g = g.emit_inst(Mov(Reg8("al"), Imm8(120))) // 'x'
                g = g.emit_inst(Mov(MemIndirect("rdi"), Reg8("al")))
                g = g.emit_inst(Inc(Reg64("rdi")))
                g = g.emit_inst(Inc(Reg64("rcx")))
                // Return
                g = g.emit_inst(Lea(Reg64("rax"), RipRel32(flt_buf)))
                g = g.emit_inst(Add(Reg64("rax"), Imm32(40)))
                g = g.emit_inst(Mov(Reg64("rdx"), Reg64("rcx")))
                g = g.emit_inst(Pop(Reg64("rdi")))
                g = g.emit_inst(Pop(Reg64("rsi")))
                g = g.emit_inst(Pop(Reg64("rcx")))
                g = g.emit_inst(Pop(Reg64("rbx")))
                g
              } else {
                self.emit_inst(Mov(Reg64("rax"), Imm32(0)))
              }
            _ => {
              // Check if this is an enum constructor
              let variant_name = {
                let parts = func_name.split("::").to_array()
                if parts.length() == 2 {
                  Some(parts[1].to_string())
                } else if self.enum_discriminants.get(func_name) != None {
                  Some(func_name.to_string())
                } else {
                  None
                }
              }
              match variant_name {
                Some(vname) =>
                  match self.enum_discriminants.get(vname) {
                    Some(disc) => {
                      let num_args = args.length()
                      if num_args == 0 {
                        // Simple enum (no data) - just return the discriminant directly
                        self.emit_inst(Mov(Reg64("rax"), Imm32(disc)))
                      } else {
                        // Enum with data - use global buffer
                        // Each enum takes (1 + num_args) * 8 bytes
                        let total_size = (num_args + 1) * 8
                        let mut g = self
                        // Get current offset
                        let offset = g.enum_buf_offset
                        // Update offset for next enum
                        g = { ..g, enum_buf_offset: offset + total_size }
                        // Store discriminant at buffer offset
                        g = g.emit_inst(Mov(Reg64("rax"), Imm32(disc)))
                        // Store at .Lenum_buf + offset
                        // Use rdx as temp
                        g = g.emit_inst(
                          Lea(Reg64("rdx"), RipRel32(".Lenum_buf")),
                        )
                        g = g.emit_inst(Add(Reg64("rdx"), Imm32(offset)))
                        g = g.emit_inst(Mov(MemIndirect("rdx"), Reg64("rax")))
                        // Store arguments at buffer + offset + 8, +16, etc.
                        let mut arg_idx = 0
                        while arg_idx < num_args {
                          g = g.codegen_expr(args[arg_idx])
                          g = g.emit_inst(
                            Lea(Reg64("rdx"), RipRel32(".Lenum_buf")),
                          )
                          g = g.emit_inst(
                            Add(Reg64("rdx"), Imm32(offset + (arg_idx + 1) * 8)),
                          )
                          g = g.emit_inst(Mov(MemIndirect("rdx"), Reg64("rax")))
                          arg_idx = arg_idx + 1
                        }
                        // Return pointer to buffer + offset
                        g = g.emit_inst(
                          Lea(Reg64("rax"), RipRel32(".Lenum_buf")),
                        )
                        g = g.emit_inst(Add(Reg64("rax"), Imm32(offset)))
                        g
                      }
                    }
                    None => {
                      // Check for built-in test functions
                      let g = if func_name == "assert_eq" && args.length() == 2 {
                        // assert_eq(expected, actual) - compare two values
                        let mut g = self.codegen_expr(args[0]) // rax = expected
                        g = g.emit_inst(Push(Reg64("rax"))) // save expected
                        g = g.codegen_expr(args[1]) // rax = actual
                        g = g.emit_inst(Pop(Reg64("rdi"))) // rdi = expected
                        g = g.emit_inst(Cmp(Reg64("rdi"), Reg64("rax")))
                        let (g_ok, ok_label) = g.new_label()
                        let (g_fail, fail_label) = g_ok.new_label()
                        g = g_ok
                        g = g.emit_inst(Je(fail_label)) // if equal, skip error
                        // Not equal - print error
                        let (g2, err_msg) = g.add_string("FAILED\n")
                        g = g2
                        g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(err_msg)))
                        g = g.emit_inst(Mov(Reg64("rdx"), Imm32(7)))
                        g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                        g = g.emit_inst(Mov(Reg64("rdi"), Imm32(1)))
                        g = g.emit_inst(Syscall)
                        g = g.define_label(fail_label)
                        g
                      } else if func_name == "assert_true" && args.length() == 1 {
                        // assert_true(condition) - fail if condition is false
                        let mut g = self.codegen_expr(args[0]) // rax = condition
                        g = g.emit_inst(Cmp(Reg64("rax"), Imm32(0)))
                        let (g_ok, ok_label) = g.new_label()
                        let (g_fail, fail_label) = g_ok.new_label()
                        g = g_ok
                        g = g.emit_inst(Je(fail_label)) // if false (0), fail
                        // True - continue (pass), skip fail
                        g = g.emit_inst(Jmp(ok_label))
                        g = g.define_label(fail_label)
                        // Failed
                        let (g2, err_msg) = g.add_string("FAILED\n")
                        g = g2
                        g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(err_msg)))
                        g = g.emit_inst(Mov(Reg64("rdx"), Imm32(7)))
                        g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                        g = g.emit_inst(Mov(Reg64("rdi"), Imm32(1)))
                        g = g.emit_inst(Syscall)
                        g = g.define_label(ok_label)
                        g
                      } else if func_name == "assert_false" &&
                        args.length() == 1 {
                        // assert_false(condition) - fail if condition is true
                        let mut g = self.codegen_expr(args[0]) // rax = condition
                        g = g.emit_inst(Cmp(Reg64("rax"), Imm32(0)))
                        let (g_ok, ok_label) = g.new_label()
                        let (g_fail, fail_label) = g_ok.new_label()
                        g = g_ok
                        g = g.emit_inst(Jne(fail_label)) // if not equal to 0 (true), fail
                        // False - continue (pass), skip fail
                        g = g.emit_inst(Jmp(ok_label))
                        g = g.define_label(fail_label)
                        // Failed
                        let (g2, err_msg) = g.add_string("FAILED\n")
                        g = g2
                        g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(err_msg)))
                        g = g.emit_inst(Mov(Reg64("rdx"), Imm32(7)))
                        g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                        g = g.emit_inst(Mov(Reg64("rdi"), Imm32(1)))
                        g = g.emit_inst(Syscall)
                        g
                      } else if func_name == "assert_false" &&
                        args.length() == 1 {
                        // assert_false(condition) - fail if condition is true
                        let mut g = self.codegen_expr(args[0]) // rax = condition
                        g = g.emit_inst(Cmp(Reg64("rax"), Imm32(0)))
                        let (g_ok, ok_label) = g.new_label()
                        let (g_fail, fail_label) = g_ok.new_label()
                        g = g_ok
                        g = g.emit_inst(Jne(fail_label)) // if true (not 0), fail
                        // False - pass, skip fail
                        g = g.emit_inst(Jmp(ok_label))
                        g = g.define_label(fail_label)
                        // Failed
                        let (g2, err_msg) = g.add_string("FAILED\n")
                        g = g2
                        g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(err_msg)))
                        g = g.emit_inst(Mov(Reg64("rdx"), Imm32(7)))
                        g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                        g = g.emit_inst(Mov(Reg64("rdi"), Imm32(1)))
                        g = g.emit_inst(Syscall)
                        g = g.define_label(ok_label)
                        g
                      } else if func_name == "inspect" && args.length() >= 1 {
                        // inspect(value) - evaluate and discard
                        let mut g = self.codegen_expr(args[0])
                        g = g.emit_inst(Mov(Reg64("rax"), Imm32(0)))
                        g
                      } else {
                        // Not a built-in, treat as regular function
                        self.codegen_user_func_call2(func_name, args)
                      }
                      g
                    }
                  }
                None => {
                  // Check for built-in test functions
                  let g = if func_name == "assert_eq" && args.length() == 2 {
                    // assert_eq(expected, actual)
                    let mut g = self.codegen_expr(args[0])
                    g = g.emit_inst(Push(Reg64("rax")))
                    g = g.codegen_expr(args[1])
                    g = g.emit_inst(Pop(Reg64("rdi")))
                    g = g.emit_inst(Cmp(Reg64("rdi"), Reg64("rax")))
                    let (g_ok, ok_label) = g.new_label()
                    let (g_fail, fail_label) = g_ok.new_label()
                    g = g_ok
                    g = g.emit_inst(Je(fail_label)) // if equal, skip error
                    let (g2, err_msg) = g.add_string("FAILED\n")
                    g = g2
                    g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(err_msg)))
                    g = g.emit_inst(Mov(Reg64("rdx"), Imm32(7)))
                    g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                    g = g.emit_inst(Mov(Reg64("rdi"), Imm32(1)))
                    g = g.emit_inst(Syscall)
                    g = g.define_label(fail_label)
                    g
                  } else if func_name == "assert_true" && args.length() == 1 {
                    let mut g = self.codegen_expr(args[0])
                    g = g.emit_inst(Cmp(Reg64("rax"), Imm32(0)))
                    let (g_ok, ok_label) = g.new_label()
                    let (g_fail, fail_label) = g_ok.new_label()
                    g = g_ok
                    g = g.emit_inst(Je(fail_label)) // if false, fail
                    // True - pass, skip fail
                    g = g.emit_inst(Jmp(ok_label))
                    g = g.define_label(fail_label)
                    let (g2, err_msg) = g.add_string("FAILED\n")
                    g = g2
                    g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(err_msg)))
                    g = g.emit_inst(Mov(Reg64("rdx"), Imm32(7)))
                    g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                    g = g.emit_inst(Mov(Reg64("rdi"), Imm32(1)))
                    g = g.emit_inst(Syscall)
                    g = g.define_label(ok_label)
                    g
                  } else if func_name == "assert_false" && args.length() == 1 {
                    let mut g = self.codegen_expr(args[0])
                    g = g.emit_inst(Cmp(Reg64("rax"), Imm32(0)))
                    let (g_ok, ok_label) = g.new_label()
                    let (g_fail, fail_label) = g_ok.new_label()
                    g = g_ok
                    g = g.emit_inst(Jne(fail_label)) // if true, fail
                    // False - pass, skip fail
                    g = g.emit_inst(Jmp(ok_label))
                    g = g.define_label(fail_label)
                    let (g2, err_msg) = g.add_string("FAILED\n")
                    g = g2
                    g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(err_msg)))
                    g = g.emit_inst(Mov(Reg64("rdx"), Imm32(7)))
                    g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
                    g = g.emit_inst(Mov(Reg64("rdi"), Imm32(1)))
                    g = g.emit_inst(Syscall)
                    g = g.define_label(ok_label)
                    g
                  } else if func_name == "inspect" && args.length() >= 1 {
                    let mut g = self.codegen_expr(args[0])
                    g = g.emit_inst(Mov(Reg64("rax"), Imm32(0)))
                    g
                  } else {
                    self.codegen_user_func_call2(func_name, args)
                  }
                  g
                }
              }
            }
          }
        }
      }
    IfExpr(cond, then, else_opt) => {
      let (g_end, end_label) = self.new_label()
      let (g_else, else_label) = g_end.new_label()
      let mut g = g_else.codegen_expr(cond)
      g = g.emit_inst(Cmp(Reg64("rax"), Imm32(0)))
      g = g.emit_inst(Je(else_label))
      g = g.codegen_expr(then)
      g = g.emit_inst(Jmp(end_label))
      g = g.define_label(else_label)
      match else_opt {
        Some(else_body) => g = g.codegen_expr(else_body)
        None => ()
      }
      g = g.define_label(end_label)
      g
    }
    Block(stmts) => {
      let mut g = self
      let mut i = 0
      while i < stmts.length() {
        g = g.codegen_expr(stmts[i])
        i = i + 1
      }
      g
    }
    ArrayLit(elems) => {
      let num_elems = elems.length()
      let mut g = self
      g = g.emit_inst(Push(Reg64("rbx")))
      g = g.emit_inst(Mov(Reg64("rbx"), Imm32(0)))
      let mut i = num_elems - 1
      while i >= 0 {
        match elems[i] {
          Spread(arr_expr) => {
            g = g.codegen_expr(arr_expr)
            let (g2, skip_label) = g.new_label()
            let (g3, loop_label) = g2.new_label()
            g = g3
            g = g.emit_inst(Cmp(Reg64("rax"), Imm32(0)))
            g = g.emit_inst(Je(skip_label))
            g = g.emit_inst(Mov(Reg64("rcx"), MemIndirect("rax")))
            g = g.emit_inst(Add(Reg64("rbx"), Reg64("rcx")))
            g = g.emit_inst(Mov(Reg64("rsi"), Imm32(0)))
            g = g.emit_inst(Mov(Reg64("rdi"), Imm32(8)))
            g = g.emit_inst(Imul(Reg64("rdi"), Reg64("rcx")))
            g = g.emit_inst(Add(Reg64("rdi"), Reg64("rax")))
            g = g.define_label(loop_label)
            g = g.emit_inst(Mov(Reg64("rcx"), MemIndirect("rax")))
            g = g.emit_inst(Cmp(Reg64("rsi"), Reg64("rcx")))
            g = g.emit_inst(Je(skip_label))
            g = g.emit_inst(Mov(Reg64("rcx"), MemIndirect("rdi")))
            g = g.emit_inst(Push(Reg64("rcx")))
            g = g.emit_inst(Sub(Reg64("rdi"), Imm32(8)))
            g = g.emit_inst(Inc(Reg64("rsi")))
            g = g.emit_inst(Jmp(loop_label))
            g = g.define_label(skip_label)
          }
          _ => {
            g = g.codegen_expr(elems[i])
            g = g.emit_inst(Push(Reg64("rax")))
            g = g.emit_inst(Inc(Reg64("rbx")))
          }
        }
        i = i - 1
      }
      let alloc_lbl = ".Larray_alloc_offset"
      let buf_lbl = ".Larrcat_buf"
      g = g.emit_inst(Lea(Reg64("rdi"), RipRel32(alloc_lbl)))
      g = g.emit_inst(Mov(Reg64("rsi"), MemIndirect("rdi")))
      g = g.emit_inst(Mov(Reg64("rcx"), Reg64("rbx")))
      g = g.emit_inst(Inc(Reg64("rcx")))
      g = g.emit_inst(Shl(Reg64("rcx"), Imm8(3)))
      g = g.emit_inst(Lea(Reg64("rdx"), RipRel32(buf_lbl)))
      g = g.emit_inst(Add(Reg64("rdx"), Reg64("rsi")))
      g = g.emit_inst(Add(Reg64("rsi"), Reg64("rcx")))
      g = g.emit_inst(Add(Reg64("rsi"), Imm32(1024)))
      g = g.emit_inst(Mov(MemIndirect("rdi"), Reg64("rsi")))
      g = g.emit_inst(Mov(MemIndirect("rdx"), Reg64("rbx")))
      let (g2, pop_loop) = g.new_label()
      let (g3, pop_done) = g2.new_label()
      g = g3
      g = g.emit_inst(Mov(Reg64("rdi"), Reg64("rdx")))
      g = g.emit_inst(Add(Reg64("rdi"), Imm32(8)))
      g = g.emit_inst(Mov(Reg64("rsi"), Imm32(0)))
      g = g.define_label(pop_loop)
      g = g.emit_inst(Cmp(Reg64("rsi"), Reg64("rbx")))
      g = g.emit_inst(Je(pop_done))
      g = g.emit_inst(Pop(Reg64("rax")))
      g = g.emit_inst(Mov(MemIndirect("rdi"), Reg64("rax")))
      g = g.emit_inst(Add(Reg64("rdi"), Imm32(8)))
      g = g.emit_inst(Inc(Reg64("rsi")))
      g = g.emit_inst(Jmp(pop_loop))
      g = g.define_label(pop_done)
      g = g.emit_inst(Mov(Reg64("rax"), Reg64("rdx")))
      g = g.emit_inst(Pop(Reg64("rbx")))
      g
    }
    MapLit(entries) => {
      // Generate code for map literal: { "key1": value1, "key2": value2, ... }
      // Store entries in map buffer: [num_entries: 4][key_ptr: 8][value: 8]...
      // Returns offset into map buffer
      let num_entries = entries.length()
      let g = { ..self, needs_map_buf: true }
      // First, evaluate all keys and values and push them onto stack
      let mut g2 = g
      let mut i = num_entries - 1
      while i >= 0 {
        let (key_expr, val_expr) = entries[i]
        // Evaluate value first
        g2 = g2.codegen_expr(val_expr)
        g2 = g2.emit_inst(Push(Reg64("rax")))
        // Then evaluate key
        g2 = g2.codegen_expr(key_expr)
        g2 = g2.emit_inst(Push(Reg64("rax")))
        i = i - 1
      }
      // Now store entries to map buffer
      // Calculate offset: map_buf_offset (starts at 0)
      let entry_size = 16 // 8 bytes key + 8 bytes value
      let map_size = 4 + num_entries * entry_size
      // Load map buffer address into rdi
      let buf_label = ".Lmap_buf"
      g2 = g2.emit_inst(Lea(Reg64("rdi"), RipRel32(buf_label)))
      // Add current offset
      g2 = g2.emit_inst(Add(Reg64("rdi"), Imm32(g2.map_buf_offset)))
      // Store num_entries (4 bytes)
      g2 = g2.emit_inst(Mov(MemOffset("rdi", 0), Imm32(num_entries)))
      // Store each entry
      let mut j = 0
      while j < num_entries {
        let key_offset = 4 + j * entry_size
        let val_offset = 4 + j * entry_size + 8
        // First pop gets key (last pushed)
        g2 = g2.emit_inst(Pop(Reg64("rax")))
        // Store at key_offset (4 + j*16)
        g2 = g2.emit_inst(Mov(MemOffset("rdi", key_offset), Reg64("rax")))
        // Second pop gets value
        g2 = g2.emit_inst(Pop(Reg64("rax")))
        // Store at val_offset (4 + j*16 + 8)
        g2 = g2.emit_inst(Mov(MemOffset("rdi", val_offset), Reg64("rax")))
        j = j + 1
      }
      // Return the offset as the map handle
      g2 = g2.emit_inst(Mov(Reg64("rax"), Imm32(g2.map_buf_offset)))
      // Update map buffer offset for next map
      { ..g2, map_buf_offset: g2.map_buf_offset + map_size }
    }
    IndexExpr(arr, idx) => {
      let is_str = is_string_expr(arr, self.var_is_string)
      let is_map = is_map_expr(arr, self.var_is_map)
      let mut g = self.codegen_expr(arr)
      // Save array/string/map address on stack
      g = g.emit_inst(Push(Reg64("rax")))
      // Evaluate index/key
      g = g.codegen_expr(idx)
      // rax = index (for array/string) or key pointer (for map)
      if is_map {
        // Map access: look up value in map buffer
        // Stack has: [map_offset]
        g = g.emit_inst(Pop(Reg64("rsi"))) // rsi = map offset (save before key eval)
        // Evaluate key (result in rax, but we ignore for now)
        // Load map buffer base address into rdi
        let buf_label = ".Lmap_buf"
        g = g.emit_inst(Lea(Reg64("rdi"), RipRel32(buf_label)))
        // Add offset to get actual map address
        g = g.emit_inst(Add(Reg64("rdi"), Reg64("rsi")))
        // Value is now at offset 12 (key at offset 4)
        g = g.emit_inst(Mov(Reg64("rax"), MemOffset("rdi", 12)))
        g
      } else {
        // Array or string indexing
        // Pop the address
        g = g.emit_inst(Pop(Reg64("rcx")))
        // rcx = array/string address, rax = index
        if is_str {
          // String: add index to address, load byte
          g = g.emit_inst(Add(Reg64("rcx"), Reg64("rax")))
          let g2 = g.emit_inst(Movzx(Reg64("rax"), MemIndirect("rcx")))
          g2
        } else {
          // Array: index * 8 + address + 8
          g = g.emit_inst(Mov(Reg64("rsi"), Imm32(8)))
          g = g.emit_inst(Imul(Reg64("rax"), Reg64("rsi")))
          g = g.emit_inst(Add(Reg64("rcx"), Reg64("rax")))
          let g2 = g.emit_inst(Mov(Reg64("rax"), MemIndirect("rcx")))
          g2
        }
      }
    }
    Tuple(elems) => {
      let num_elems = elems.length()
      if num_elems == 0 {
        self.emit_inst(Mov(Reg64("rax"), Imm32(0)))
      } else {
        let mut g = self
        // Push elements in reverse order so first element ends up at lowest address
        let mut i = num_elems - 1
        while i >= 0 {
          let elem_is_float = is_float_expr(elems[i], g.var_is_float)
          g = g.codegen_expr(elems[i])
          if elem_is_float {
            // Float is in xmm0, push it to stack
            g = g.emit_inst(Sub(Reg64("rsp"), Imm32(8)))
            g = g.emit_inst(Movsd(MemIndirect("rsp"), Xmm("xmm0")))
          } else {
            g = g.emit_inst(Push(Reg64("rax")))
          }
          i = i - 1
        }
        // rsp now points to first element (elem0)
        // Return the address of the tuple (rsp)
        g = g.emit_inst(Mov(Reg64("rax"), Reg64("rsp")))
        g
      }
    }
    FieldExpr(obj, field) => {
      let idx = if field.length() > 0 {
        let c = field[0]
        if c >= '0' && c <= '9' {
          c.to_int() - 48
        } else {
          match obj {
            Ident(var_name) =>
              // First try var_struct_fields (for anonymous structs)
              match self.var_struct_fields.get(var_name) {
                Some(field_names) => {
                  let mut i = 0
                  let mut found = 0
                  while i < field_names.length() {
                    if field_names[i] == field {
                      found = i
                    }
                    i = i + 1
                  }
                  found
                }
                None =>
                  // Then try var_types -> struct_fields (for named structs)
                  match self.var_types.get(var_name) {
                    Some(type_name) =>
                      match self.struct_fields.get(type_name) {
                        Some(field_names) => {
                          let mut i = 0
                          let mut found = 0
                          while i < field_names.length() {
                            if field_names[i] == field {
                              found = i
                            }
                            i = i + 1
                          }
                          found
                        }
                        None => 0
                      }
                    None => 0
                  }
              }
            _ => 0
          }
        }
      } else {
        0
      }
      let (g, base_offset) = match obj {
        Ident(var_name) =>
          match self.var_offsets.get(var_name) {
            Some(offset) => (self, offset)
            None => {
              let g = self.codegen_expr(obj)
              (g, 0)
            }
          }
        _ => {
          let g = self.codegen_expr(obj)
          (g, 0)
        }
      }
      let field_is_float = match obj {
        Ident(var_name) =>
          match self.var_tuple_field_types.get(var_name) {
            Some(types) => idx < types.length() && types[idx]
            None => false
          }
        _ => false
      }
      // For structs: base_offset is the offset from rbp to field 0
      // Field idx is at base_offset + idx * 8
      let total_offset = base_offset + idx * 8
      let g = g.emit_inst(Push(Reg64("rbx")))
      let g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rbp")))
      let g = if total_offset >= 0 {
        g.emit_inst(Add(Reg64("rbx"), Imm32(total_offset)))
      } else {
        g.emit_inst(Sub(Reg64("rbx"), Imm32(-total_offset)))
      }
      let g = if field_is_float {
        g.emit_inst(Movsd(Xmm("xmm0"), MemIndirect("rbx")))
      } else {
        g.emit_inst(Mov(Reg64("rax"), MemIndirect("rbx")))
      }
      g.emit_inst(Pop(Reg64("rbx")))
    }
    LetBind(name, _annot, value, body) => {
      let is_float = is_float_expr(value, self.var_is_float) ||
        is_float_field_expr(value, self.var_tuple_field_types)
      let is_string = is_string_expr(value, self.var_is_string)
      let is_char = is_char_expr(value, self.var_is_char)
      let is_bool = is_bool_expr(value, self.var_is_bool)
      let is_tuple = match value {
        Tuple(_) => true
        Ident(src) => self.var_is_tuple.get(src) == Some(true)
        _ => false
      }
      let is_map = match value {
        MapLit(_) => true
        Ident(src) => self.var_is_map.get(src) == Some(true)
        _ => false
      }
      let is_struct_or_tuple = match value {
        StructLit(_, _) => true
        StructUpdate(_, _) => true
        Tuple(_) => true
        Ident(src_name) => self.var_struct_fields.get(src_name) != None
        _ => false
      }
      // Check if value is a struct variable reference (for aliasing)
      let src_struct_offset = match value {
        Ident(src_name) => self.var_offsets.get(src_name)
        _ => None
      }
      let is_struct_alias = match value {
        Ident(src_name) => self.var_struct_fields.get(src_name) != None
        _ => false
      }
      let struct_type = match value {
        StructLit(type_name, _) => Some(type_name)
        StructUpdate(base, _) =>
          match base {
            Ident(src_name) => self.var_types.get(src_name)
            _ => None
          }
        Ident(src_name) => self.var_types.get(src_name)
        _ => None
      }
      let struct_field_names = match value {
        StructLit(_, fields) => {
          let mut names : Array[String] = []
          let mut i = 0
          while i < fields.length() {
            let (fname, _) = fields[i]
            names = names + [fname]
            i = i + 1
          }
          Some(names)
        }
        StructUpdate(base, _) =>
          match base {
            Ident(src_name) => self.var_struct_fields.get(src_name)
            _ => None
          }
        Ident(src_name) => self.var_struct_fields.get(src_name)
        _ => None
      }
      let tuple_field_types = match value {
        Tuple(elems) => {
          let mut types : Array[Bool] = []
          let mut i = 0
          while i < elems.length() {
            types = types + [is_float_expr(elems[i], self.var_is_float)]
            i = i + 1
          }
          Some(types)
        }
        _ => None
      }
      let array_len = match value {
        ArrayLit(elems) => Some(elems.length())
        Binary("+", left, right) =>
          if is_array_expr(left, self.var_array_len) &&
            is_array_expr(right, self.var_array_len) {
            Some(0)
          } else {
            None
          }
        _ => None
      }
      let g = if is_struct_alias {
        // Don't evaluate for struct aliases - we just copy the offset
        self
      } else {
        self.codegen_expr(value)
      }
      let num_tuple_elems = match value {
        Tuple(elems) => elems.length()
        StructLit(_, fields) => fields.length()
        StructUpdate(base, _) =>
          match base {
            Ident(src_name) =>
              match self.var_struct_fields.get(src_name) {
                Some(fields) => fields.length()
                None => 0
              }
            _ => 0
          }
        _ => 0
      }
      let (g2, offset, is_array_val) = if is_struct_or_tuple &&
        num_tuple_elems > 0 {
        // For structs/tuples, the fields are already pushed onto the stack
        // Each element is 8 bytes, pushed in reverse order
        // The tuple starts at the current rsp, which is:
        // rbp - (stack slots used before this tuple) - num_tuple_elems * 8
        // Since we track next_offset as where the NEXT slot would go,
        // and we haven't updated next_offset during the tuple push,
        // the tuple offset is: next_offset - num_tuple_elems * 8 + 8
        // Simplify: the tuple starts at rsp, which moved by num_elems * 8 from
        // its original position. If next_offset was in sync, offset = next_offset - num_elems * 8 + 8
        // But actually, next_offset tracks the next SLOT, not the current stack position.
        // The first element pushed ends up at next_offset - 8 - (num_elems-1) * 8
        // Simplify: first element at next_offset - num_elems * 8
        // But that's wrong... Let me just compute it correctly.
        // After pushing num_elems elements, rsp = original_rsp - num_elems * 8
        // original_rsp = rbp + next_offset + 8 (since next_offset points to the NEXT slot)
        // Actually, next_offset = -(slots_used * 8), and slots_used = (num previous pushes)
        // After tuple pushes: rsp = rbp - (slots_used + num_tuple_elems) * 8
        // So offset = -(slots_used + num_tuple_elems) * 8 = next_offset - num_tuple_elems * 8
        // But wait, slots_used = -next_offset / 8, so after tuple, slots_used increases by num_tuple_elems
        // Let me just compute: offset = -(num_tuple_elems) * 8 relative to rbp
        // Since rsp started at rbp (no previous pushes), offset = -num_tuple_elems * 8
        // But we also need to account for previous local variables...
        // The correct formula: offset = next_offset - num_tuple_elems * 8 + 8
        // No, that's still wrong. Let me trace through more carefully:
        // - next_offset starts at -8 (meaning first local var will be at rbp - 8)
        // - Before tuple, nothing pushed, rsp = rbp
        // - After tuple (num_elems = 2): rsp = rbp - 16
        // - Tuple should be at rbp - 16, so offset = -16
        // - Formula: offset = -num_tuple_elems * 8 = -16 ✓
        // But this doesn't use next_offset...
        // The issue is next_offset isn't tracking the actual stack position
        // Let's fix the formula: offset = -(num_tuple_elems) * 8
        // But we need to account for previous vars too...
        // After a previous var: next_offset = -16, rsp = rbp - 8
        // After tuple: rsp = rbp - 8 - 16 = rbp - 24
        // So offset = next_offset - num_tuple_elems * 8 = -16 - 16 = -32... wrong!
        // The tuple should be at rbp - 24, not -32
        // So the formula should be: offset = next_offset - num_tuple_elems * 8 + 8
        // = -16 - 16 + 8 = -24 ✓
        // For the first var (next_offset = -8, no previous pushes):
        // offset = -8 - 16 + 8 = -16 ✓
        (g, g.next_offset - num_tuple_elems * 8 + 8, false)
      } else if is_struct_alias {
        // Struct alias - don't push anything, just use the source's offset
        let src_off = match src_struct_offset {
          Some(off) => off
          None => g.next_offset
        }
        (g, src_off, false)
      } else if is_struct_or_tuple {
        // Empty struct/tuple
        (g, g.next_offset, false)
      } else if is_float {
        let g = g.emit_inst(PushXmm("xmm0"))
        (g, g.next_offset, false)
      } else {
        let g = g.emit_inst(Push(Reg64("rax")))
        (g, g.next_offset, false)
      }
      let g3 = {
        let new_offsets = g2.var_offsets
        new_offsets[name] = offset
        let new_floats = g2.var_is_float
        new_floats[name] = is_float
        let new_strings = g2.var_is_string
        new_strings[name] = is_string
        let new_chars = g2.var_is_char
        new_chars[name] = is_char
        let new_bools = g2.var_is_bool
        new_bools[name] = is_bool
        let new_tuples = g2.var_is_tuple
        // Also set is_tuple based on whether tuple_field_types was computed
        let should_be_tuple = tuple_field_types != None
        new_tuples[name] = is_tuple || should_be_tuple
        let new_maps = g2.var_is_map
        new_maps[name] = is_map
        let new_array_lens = g2.var_array_len
        match array_len {
          Some(len) => new_array_lens[name] = len
          None => ()
        }
        let new_types = g2.var_types
        match struct_type {
          Some(type_name) => new_types[name] = type_name
          None => ()
        }
        let new_struct_fields = g2.var_struct_fields
        match struct_field_names {
          Some(names) => new_struct_fields[name] = names
          None => ()
        }
        let new_tuple_field_types = g2.var_tuple_field_types
        match tuple_field_types {
          Some(types) => new_tuple_field_types[name] = types
          None => ()
        }
        let new_next_offset = offset - 8
        {
          ..g2,
          var_offsets: new_offsets,
          var_is_float: new_floats,
          var_is_string: new_strings,
          var_is_char: new_chars,
          var_is_bool: new_bools,
          var_is_tuple: new_tuples,
          var_is_map: new_maps,
          var_tuple_field_types: new_tuple_field_types,
          var_array_len: new_array_lens,
          var_types: new_types,
          var_struct_fields: new_struct_fields,
          next_offset: new_next_offset,
        }
      }
      g3.codegen_expr(body)
    }
    Func(name, _params, _ret, body) =>
      if name == "main" {
        self.codegen_expr(body)
      } else {
        // Non-main functions are emitted later by codegen(), skip here
        self
      }
    ReturnExpr(e) => {
      let g = self.codegen_expr(e)
      g.emit_inst(Ret)
    }
    WhileLoop(cond, body) => {
      let start_label = ".Lwhile_start\{self.label_counter}"
      let end_label = ".Lwhile_end\{self.label_counter + 1}"
      let mut g = { ..self, label_counter: self.label_counter + 2 }
      // Push loop labels for break/continue
      // For while: continue goes to start (re-check condition)
      g = { ..g, loop_labels: g.loop_labels + [(end_label, start_label)] }
      // Define start label
      g = g.define_label(start_label)
      // Evaluate condition
      g = g.codegen_expr(cond)
      // If condition is 0 (false), jump to end
      g = g.emit_inst(Cmp(Reg64("rax"), Imm32(0)))
      g = g.emit_inst(Je(end_label))
      // Evaluate body
      g = g.codegen_expr(body)
      // Jump back to start
      g = g.emit_inst(Jmp(start_label))
      // Define end label
      g = g.define_label(end_label)
      // Pop loop labels
      let new_labels = g.loop_labels
      ignore(new_labels.pop())
      { ..g, loop_labels: new_labels }
    }
    ForLoop(init, cond, step, body) => {
      let step_label = ".Lfor_step\{self.label_counter}"
      let cond_label = ".Lfor_cond\{self.label_counter + 1}"
      let end_label = ".Lfor_end\{self.label_counter + 2}"
      let mut g = { ..self, label_counter: self.label_counter + 3 }
      // Push loop labels for break/continue
      // For for: continue goes to step label
      g = { ..g, loop_labels: g.loop_labels + [(end_label, step_label)] }
      // Execute init
      match init {
        Some(i) => g = g.codegen_expr(i)
        None => ()
      }
      // Define condition label
      g = g.define_label(cond_label)
      // Evaluate condition (default to true if none)
      match cond {
        Some(c) => {
          g = g.codegen_expr(c)
          g = g.emit_inst(Cmp(Reg64("rax"), Imm32(0)))
          g = g.emit_inst(Je(end_label))
        }
        None => ()
      }
      // Evaluate body
      g = g.codegen_expr(body)
      // Define step label
      g = g.define_label(step_label)
      // Execute step
      match step {
        Some(s) => g = g.codegen_expr(s)
        None => ()
      }
      // Jump back to condition
      g = g.emit_inst(Jmp(cond_label))
      // Define end label
      g = g.define_label(end_label)
      // Pop loop labels
      let new_labels = g.loop_labels
      ignore(new_labels.pop())
      { ..g, loop_labels: new_labels }
    }
    ForInLoop(var_name, iter, body) => {
      // for-in loop: for x in arr { body }
      // Array layout: [length][elem0][elem1]...
      // Use callee-saved registers: r12=array, r13=length, r14=counter
      let mut g = self
      // Save callee-saved registers
      g = g.emit_inst(Push(Reg64("r12")))
      g = g.emit_inst(Push(Reg64("r13")))
      g = g.emit_inst(Push(Reg64("r14")))
      // 1. Evaluate the array expression
      g = g.codegen_expr(iter)
      // rax = array address, save to r12
      g = g.emit_inst(Mov(Reg64("r12"), Reg64("rax")))
      // 2. Load array length (first 8 bytes at array address)
      g = g.emit_inst(Mov(Reg64("r13"), MemIndirect("rax"))) // r13 = array length
      // 3. Initialize counter at 0, save to r14
      g = g.emit_inst(Mov(Reg64("r14"), Imm32(0)))
      // 4. Create loop labels
      let loop_label = ".Lforin_loop\{self.label_counter}"
      let end_label = ".Lforin_end\{self.label_counter + 1}"
      g = { ..g, label_counter: self.label_counter + 2 }
      g = { ..g, loop_labels: g.loop_labels + [(end_label, loop_label)] }
      // Define loop label
      g = g.define_label(loop_label)
      // 5. Check if counter >= length
      g = g.emit_inst(Mov(Reg64("rax"), Reg64("r14"))) // rax = counter
      g = g.emit_inst(Mov(Reg64("rbx"), Reg64("r13"))) // rbx = length
      g = g.emit_inst(Cmp(Reg64("rax"), Reg64("rbx")))
      g = g.emit_inst(Jge(end_label))
      // 6. Load array element at index counter
      // element_addr = array_addr + counter*8 + 8
      g = g.emit_inst(Mov(Reg64("rcx"), Reg64("r12"))) // rcx = array_addr
      // Multiply counter by 8
      g = g.emit_inst(Mov(Reg64("rax"), Reg64("r14"))) // rax = counter
      g = g.emit_inst(Mov(Reg64("rdx"), Imm32(8)))
      g = g.emit_inst(Imul(Reg64("rax"), Reg64("rdx"))) // rax = counter * 8
      // Add to array address
      g = g.emit_inst(Add(Reg64("rcx"), Reg64("rax"))) // rcx = array_addr + counter*8
      g = g.emit_inst(Add(Reg64("rcx"), Imm32(8))) // rcx = array_addr + counter*8 + 8
      // Load element into rax
      g = g.emit_inst(Mov(Reg64("rax"), MemIndirect("rcx")))
      // 7. Store into loop variable
      let offset = g.next_offset - 8
      let new_offsets = g.var_offsets
      new_offsets[var_name] = offset
      g = { ..g, next_offset: offset, var_offsets: new_offsets }
      g = g.emit_inst(Mov(StackBP64(offset), Reg64("rax")))
      // 8. Execute body
      g = g.codegen_expr(body)
      // 9. Increment counter
      g = g.emit_inst(Inc(Reg64("r14"))) // r14 = counter + 1
      // 10. Jump back to loop
      g = g.emit_inst(Jmp(loop_label))
      // 11. Define end label
      g = g.define_label(end_label)
      // Pop loop labels
      let new_labels = g.loop_labels
      ignore(new_labels.pop())
      // Restore callee-saved registers
      g = g.emit_inst(Pop(Reg64("r14")))
      g = g.emit_inst(Pop(Reg64("r13")))
      g = g.emit_inst(Pop(Reg64("r12")))
      { ..g, loop_labels: new_labels }
    }
    Break =>
      // Jump to break label of innermost loop
      if self.loop_labels.length() > 0 {
        let (break_label, _) = self.loop_labels[self.loop_labels.length() - 1]
        self.emit_inst(Jmp(break_label))
      } else {
        self
      }
    Continue =>
      // Jump to continue label of innermost loop
      if self.loop_labels.length() > 0 {
        let (_, continue_label) = self.loop_labels[self.loop_labels.length() - 1]
        self.emit_inst(Jmp(continue_label))
      } else {
        self
      }
    MatchExpr(scrutinee, cases) => {
      let mut g = self
      g = g.codegen_expr(scrutinee)
      g = g.emit_inst(Push(Reg64("rax")))
      let end_label = ".Lmatch_end\{g.label_counter}"
      g = { ..g, label_counter: g.label_counter + 1 }
      // Always need end_label for cleanup
      let mut need_end_label = true
      let mut case_idx = 0
      while case_idx < cases.length() {
        let (pattern, body) = cases[case_idx]
        let is_last = case_idx == cases.length() - 1
        match pattern {
          Int(n) => {
            g = g.emit_inst(Mov(Reg64("rcx"), MemIndirect("rsp")))
            g = g.emit_inst(Cmp(Reg64("rcx"), Imm32(n)))
            if is_last {
              // For last case, need to skip body if no match
              let skip_body = ".Lmatch_skip_int\{g.label_counter}"
              g = { ..g, label_counter: g.label_counter + 1 }
              g = g.emit_inst(Jne(skip_body))
              g = g.codegen_expr(body)
              g = g.emit_inst(Jmp(end_label))
              g = g.define_label(skip_body)
            } else {
              let next_case = ".Lmatch_next\{g.label_counter}"
              g = { ..g, label_counter: g.label_counter + 1 }
              g = g.emit_inst(Jne(next_case))
              g = g.codegen_expr(body)
              g = g.emit_inst(Jmp(end_label))
              g = g.define_label(next_case)
            }
          }
          Ident(var_name) => {
            // For enum pattern matching, the value might be:
            // - A direct discriminant (for simple enums without data, typically small numbers like 0, 1, 2)
            // - A pointer to enum structure (for enums with data, always non-zero and typically large)
            // We use a threshold to distinguish: small values (<4096) are discriminants, large values are pointers
            let disc_val = match g.enum_discriminants.get(var_name) {
              Some(disc) => Some(disc)
              None => {
                let parts = var_name.split("::").to_array()
                if parts.length() == 2 {
                  g.enum_discriminants.get(parts[1].to_string())
                } else {
                  None
                }
              }
            }
            match disc_val {
              Some(disc) => {
                // Load the value from stack into rcx
                g = g.emit_inst(Mov(Reg64("rcx"), MemIndirect("rsp")))
                // Check if value is small (< 256) - likely a direct discriminant
                // If large - treat as pointer and dereference
                g = g.emit_inst(Cmp(Reg64("rcx"), Imm32(256)))
                let (g2, is_small_label) = g.new_label()
                let (g3, is_pointer_label) = g2.new_label()
                g = g3
                g = g.emit_inst(Jb(is_small_label)) // if < 256, treat as direct
                // Large value - treat as pointer, load discriminant from pointer
                g = g.emit_inst(Mov(Reg64("rcx"), MemIndirect("rcx")))
                g = g.define_label(is_small_label)
                // Now rcx has the discriminant (either direct or dereferenced)
                g = g.emit_inst(Cmp(Reg64("rcx"), Imm32(disc)))
                if is_last {
                  // For last case, need to skip body if no match
                  let skip_body = ".Lmatch_skip_body\{g.label_counter}"
                  g = { ..g, label_counter: g.label_counter + 1 }
                  g = g.emit_inst(Jne(skip_body))
                  g = g.codegen_expr(body)
                  g = g.emit_inst(Jmp(end_label))
                  g = g.define_label(skip_body)
                } else {
                  let next_case = ".Lmatch_next\{g.label_counter}"
                  g = { ..g, label_counter: g.label_counter + 1 }
                  g = g.emit_inst(Jne(next_case))
                  g = g.codegen_expr(body)
                  g = g.emit_inst(Jmp(end_label))
                  g = g.define_label(next_case)
                }
              }
              None => if is_last { g = g.codegen_expr(body) }
            }
          }
          CallExpr(Ident(var_name), bindings) => {
            let disc_val = match g.enum_discriminants.get(var_name) {
              Some(disc) => Some(disc)
              None => {
                let parts = var_name.split("::").to_array()
                if parts.length() == 2 {
                  g.enum_discriminants.get(parts[1].to_string())
                } else {
                  None
                }
              }
            }
            match disc_val {
              Some(disc) => {
                // For CallExpr patterns (enum constructors like RGB), the scrutinee could be:
                // - A direct discriminant (for simple enums without data, typically small numbers)
                // - A pointer to enum structure (for enums with data, always non-zero and typically large)
                // We use a threshold to distinguish: small values (<256) are discriminants, large values are pointers
                // Note: Code section typically starts at 0x400000, so any value < 0x10000 is definitely not a pointer
                // Load the value from stack into rcx
                g = g.emit_inst(Mov(Reg64("rcx"), MemIndirect("rsp")))
                // Check if value is small (< 256) - likely a direct discriminant
                // If large - treat as pointer and dereference
                g = g.emit_inst(Cmp(Reg64("rcx"), Imm32(256)))
                let (g2, is_small_label) = g.new_label()
                g = g2
                g = g.emit_inst(Jb(is_small_label)) // if < 256, treat as direct discriminant
                // Large value (>= 256) - treat as pointer, load discriminant from pointer
                g = g.emit_inst(Mov(Reg64("rcx"), MemIndirect("rcx")))
                g = g.define_label(is_small_label)
                // Now rcx has the discriminant (either direct or dereferenced)
                g = g.emit_inst(Cmp(Reg64("rcx"), Imm32(disc)))
                if is_last {
                  // Last case - if doesn't match, fall through (do nothing)
                  // If matches, execute body
                  let skip_bind = ".Lmatch_skip_bind\{g.label_counter}"
                  g = { ..g, label_counter: g.label_counter + 1 }
                  g = g.emit_inst(Jne(skip_bind))
                  // Bind fields if there are any bindings
                  let num_bindings = bindings.length()
                  if num_bindings > 0 {
                    // Store bound variables at specific stack locations
                    // Use negative offsets that won't conflict with LetBind
                    // LetBind starts from next_offset which is typically around -8 to -16
                    // We'll use -128, -136, -144, etc. to be far away
                    // Load enum pointer from stack
                    g = g.emit_inst(Mov(Reg64("r12"), MemIndirect("rsp")))
                    // Bind each field
                    let mut bind_idx = 0
                    while bind_idx < num_bindings {
                      match bindings[bind_idx] {
                        Ident(bind_name) => {
                          // Use very low stack offsets to avoid LetBind
                          let offset = -128 - bind_idx * 8
                          let new_offsets = g.var_offsets
                          new_offsets[bind_name] = offset
                          g = { ..g, var_offsets: new_offsets }
                          // Load from enum buffer: [r12 + (bind_idx + 1) * 8]
                          g = g.emit_inst(Mov(Reg64("rax"), Reg64("r12")))
                          g = g.emit_inst(
                            Mov(Reg64("rdx"), Imm32((bind_idx + 1) * 8)),
                          )
                          g = g.emit_inst(Add(Reg64("rax"), Reg64("rdx")))
                          g = g.emit_inst(Mov(Reg64("rax"), MemIndirect("rax")))
                          // Store at rbp + offset
                          g = g.emit_inst(Mov(StackBP64(offset), Reg64("rax")))
                        }
                        _ => ()
                      }
                      bind_idx = bind_idx + 1
                    }
                    g = g.codegen_expr(body)
                  } else {
                    g = g.codegen_expr(body)
                  }
                  g = g.emit_inst(Jmp(end_label))
                  g = g.define_label(skip_bind)
                } else {
                  let next_case = ".Lmatch_next\{g.label_counter}"
                  g = { ..g, label_counter: g.label_counter + 1 }
                  g = g.emit_inst(Jne(next_case))
                  // Bind fields if there are any bindings
                  let num_bindings = bindings.length()
                  if num_bindings > 0 {
                    // Store bound variables at specific stack locations
                    // Load enum pointer from stack
                    g = g.emit_inst(Mov(Reg64("r12"), MemIndirect("rsp")))
                    // Bind each field
                    let mut bind_idx = 0
                    while bind_idx < num_bindings {
                      match bindings[bind_idx] {
                        Ident(bind_name) => {
                          let offset = -128 - bind_idx * 8
                          let new_offsets = g.var_offsets
                          new_offsets[bind_name] = offset
                          g = { ..g, var_offsets: new_offsets }
                          // Load from enum buffer: [r12 + (bind_idx + 1) * 8]
                          g = g.emit_inst(Mov(Reg64("rax"), Reg64("r12")))
                          g = g.emit_inst(
                            Mov(Reg64("rdx"), Imm32((bind_idx + 1) * 8)),
                          )
                          g = g.emit_inst(Add(Reg64("rax"), Reg64("rdx")))
                          g = g.emit_inst(Mov(Reg64("rax"), MemIndirect("rax")))
                          // Store at rbp + offset
                          g = g.emit_inst(Mov(StackBP64(offset), Reg64("rax")))
                        }
                        _ => ()
                      }
                      bind_idx = bind_idx + 1
                    }
                    g = g.codegen_expr(body)
                  } else {
                    g = g.codegen_expr(body)
                  }
                  g = g.emit_inst(Jmp(end_label))
                  g = g.define_label(next_case)
                }
              }
              None => if is_last { g = g.codegen_expr(body) }
            }
          }
          _ => if is_last { g = g.codegen_expr(body) }
        }
        case_idx = case_idx + 1
      }
      // Always define end_label for cleanup
      g = g.define_label(end_label)
      g = g.emit_inst(Add(Reg64("rsp"), Imm32(8)))
      g
    }
    Assign(target, value) =>
      match target {
        Ident(name) =>
          match self.var_offsets.get(name) {
            Some(offset) => {
              // Evaluate the new value
              let g = self.codegen_expr(value)
              // Store to existing variable location
              g.emit_inst(Mov(StackBP64(offset), Reg64("rax")))
            }
            None =>
              // Variable not found, just evaluate value
              self.codegen_expr(value)
          }
        IndexExpr(arr, idx) => {
          // Check if this is a map or array/index assignment
          let is_map = is_map_expr(arr, self.var_is_map)
          if is_map {
            // Map assignment: map["key"] = value
            // Simplified: just evaluate and discard the value
            // (maps return 0 so this won't crash, just doesn't persist)
            let g = self.codegen_expr(arr)
            let g = g.codegen_expr(idx)
            g.codegen_expr(value)
          } else {
            // Array element assignment: arr[idx] = value
            // Arrays are stored as memory addresses (from rsp)
            let g = self.codegen_expr(arr)
            // Save the array address
            let g = g.emit_inst(Push(Reg64("rax")))
            // Evaluate index
            let g = g.codegen_expr(idx)
            // Multiply index by 8
            let g = g.emit_inst(Mov(Reg64("rcx"), Imm32(8)))
            let g = g.emit_inst(Imul(Reg64("rax"), Reg64("rcx")))
            // rax = index * 8
            // Pop array address
            let g = g.emit_inst(Pop(Reg64("rcx")))
            // rcx = array_addr + index*8 + 8 (skip length field)
            let g = g.emit_inst(Add(Reg64("rcx"), Reg64("rax")))
            let g = g.emit_inst(Add(Reg64("rcx"), Imm32(8)))
            // Evaluate value
            let g = g.codegen_expr(value)
            // Store value at [rcx]
            g.emit_inst(Mov(MemIndirect("rcx"), Reg64("rax")))
          }
        }
        FieldExpr(obj, field) =>
          // Field assignment: obj.field = value
          match obj {
            Ident(var_name) =>
              match self.var_offsets.get(var_name) {
                Some(base_offset) => {
                  // Get field index
                  let idx = match self.var_struct_fields.get(var_name) {
                    Some(fields) => {
                      let mut i = 0
                      let mut found = 0
                      while i < fields.length() {
                        if fields[i] == field {
                          found = i
                        }
                        i = i + 1
                      }
                      found
                    }
                    None =>
                      match self.var_types.get(var_name) {
                        Some(type_name) =>
                          match self.struct_fields.get(type_name) {
                            Some(fields) => {
                              let mut i = 0
                              let mut found = 0
                              while i < fields.length() {
                                if fields[i] == field {
                                  found = i
                                }
                                i = i + 1
                              }
                              found
                            }
                            None => 0
                          }
                        None => 0
                      }
                  }
                  // Calculate field offset: base_offset + idx * 8
                  let field_offset = base_offset + idx * 8
                  // Evaluate the new value
                  let g = self.codegen_expr(value)
                  // Store to field location
                  g.emit_inst(Mov(StackBP64(field_offset), Reg64("rax")))
                }
                None => self.codegen_expr(value)
              }
            _ => self.codegen_expr(value)
          }
        _ =>
          // Unknown assignment target
          self.codegen_expr(value)
      }
    AssignOp(op, target, value) =>
      match target {
        Ident(name) =>
          match self.var_offsets.get(name) {
            Some(offset) => {
              // Load current value
              let g = self.emit_inst(Mov(Reg64("rax"), StackBP64(offset)))
              // Push current value
              let g = g.emit_inst(Push(Reg64("rax")))
              // Evaluate the new value
              let g = g.codegen_expr(value)
              // Pop old value into rcx
              let g = g.emit_inst(Pop(Reg64("rcx")))
              // Perform operation: rcx op= rax
              // rcx = old value, rax = new value
              let g = match op {
                "+" => g.emit_inst(Add(Reg64("rcx"), Reg64("rax")))
                "-" => g.emit_inst(Sub(Reg64("rcx"), Reg64("rax")))
                "*" => g.emit_inst(Imul(Reg64("rcx"), Reg64("rax")))
                "/" => {
                  // Save divisor in rbx
                  let g = g.emit_inst(Push(Reg64("rbx")))
                  let g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rax")))
                  // Dividend in rax
                  let g = g.emit_inst(Mov(Reg64("rax"), Reg64("rcx")))
                  let g = g.emit_inst(Cqo)
                  let g = g.emit_inst(Idiv(Reg64("rbx")))
                  // Quotient in rax, move to rcx for storage
                  let g = g.emit_inst(Mov(Reg64("rcx"), Reg64("rax")))
                  g.emit_inst(Pop(Reg64("rbx")))
                }
                "%" => {
                  // Save divisor in rbx
                  let g = g.emit_inst(Push(Reg64("rbx")))
                  let g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rax")))
                  // Dividend in rax
                  let g = g.emit_inst(Mov(Reg64("rax"), Reg64("rcx")))
                  let g = g.emit_inst(Cqo)
                  let g = g.emit_inst(Idiv(Reg64("rbx")))
                  // Remainder in rdx, move to rcx
                  let g = g.emit_inst(Mov(Reg64("rcx"), Reg64("rdx")))
                  g.emit_inst(Pop(Reg64("rbx")))
                }
                "&" => g.emit_inst(And(Reg64("rcx"), Reg64("rax")))
                "|" => g.emit_inst(Or(Reg64("rcx"), Reg64("rax")))
                "^" => g.emit_inst(Xor(Reg64("rcx"), Reg64("rax")))
                "<<" => {
                  let g = g.emit_inst(Mov(Reg64("cl"), Reg64("al")))
                  g.emit_inst(Shl(Reg64("rcx"), Reg8("cl")))
                }
                ">>" => {
                  let g = g.emit_inst(Mov(Reg64("cl"), Reg64("al")))
                  g.emit_inst(Sar(Reg64("rcx"), Reg8("cl")))
                }
                _ => g
              }
              // Store result back
              g.emit_inst(Mov(StackBP64(offset), Reg64("rcx")))
            }
            None => self.codegen_expr(value)
          }
        IndexExpr(arr, idx) => {
          // Array element compound assignment: arr[idx] += value
          // Arrays are stored as memory addresses
          let g = self.codegen_expr(arr)
          let g = g.emit_inst(Push(Reg64("rax")))
          let g = g.codegen_expr(idx)
          let g = g.emit_inst(Mov(Reg64("rcx"), Imm32(8)))
          let g = g.emit_inst(Imul(Reg64("rax"), Reg64("rcx")))
          let g = g.emit_inst(Pop(Reg64("rcx")))
          let g = g.emit_inst(Add(Reg64("rcx"), Reg64("rax")))
          let g = g.emit_inst(Add(Reg64("rcx"), Imm32(8))) // skip length field
          // rcx = array_addr + 8 + index*8
          // Load current value
          let g = g.emit_inst(Mov(Reg64("rax"), MemIndirect("rcx")))
          let g = g.emit_inst(Push(Reg64("rax")))
          // Evaluate value
          let g = g.codegen_expr(value)
          // Pop old value
          let g = g.emit_inst(Pop(Reg64("rcx")))
          // Perform operation
          // rcx = old value, rax = new value
          let g = match op {
            "+" => g.emit_inst(Add(Reg64("rcx"), Reg64("rax")))
            "-" => g.emit_inst(Sub(Reg64("rcx"), Reg64("rax")))
            "*" => g.emit_inst(Imul(Reg64("rcx"), Reg64("rax")))
            "/" => {
              let g = g.emit_inst(Mov(Reg64("r8"), Reg64("rax")))
              let g = g.emit_inst(Mov(Reg64("rax"), Reg64("rcx")))
              let g = g.emit_inst(Cqo)
              let g = g.emit_inst(Idiv(Reg64("r8")))
              g.emit_inst(Mov(Reg64("rcx"), Reg64("rax")))
            }
            "%" => {
              let g = g.emit_inst(Mov(Reg64("r8"), Reg64("rax")))
              let g = g.emit_inst(Mov(Reg64("rax"), Reg64("rcx")))
              let g = g.emit_inst(Cqo)
              let g = g.emit_inst(Idiv(Reg64("r8")))
              g.emit_inst(Mov(Reg64("rcx"), Reg64("rdx")))
            }
            "&" => g.emit_inst(And(Reg64("rcx"), Reg64("rax")))
            "|" => g.emit_inst(Or(Reg64("rcx"), Reg64("rax")))
            "^" => g.emit_inst(Xor(Reg64("rcx"), Reg64("rax")))
            "<<" => {
              let g = g.emit_inst(Mov(Reg64("cl"), Reg64("al")))
              g.emit_inst(Shl(Reg64("rcx"), Reg8("cl")))
            }
            ">>" => {
              let g = g.emit_inst(Mov(Reg64("cl"), Reg64("al")))
              g.emit_inst(Sar(Reg64("rcx"), Reg8("cl")))
            }
            _ => g
          }
          // Store result - need to recalculate address
          // Push result
          let g = g.emit_inst(Push(Reg64("rcx")))
          // Recalculate address
          let g = g.codegen_expr(arr)
          let g = g.emit_inst(Push(Reg64("rax")))
          let g = g.codegen_expr(idx)
          let g = g.emit_inst(Mov(Reg64("rcx"), Imm32(8)))
          let g = g.emit_inst(Imul(Reg64("rax"), Reg64("rcx")))
          let g = g.emit_inst(Pop(Reg64("rcx")))
          let g = g.emit_inst(Add(Reg64("rcx"), Reg64("rax")))
          let g = g.emit_inst(Add(Reg64("rcx"), Imm32(8)))
          // Pop result
          let g = g.emit_inst(Pop(Reg64("rax")))
          // Store
          g.emit_inst(Mov(MemIndirect("rcx"), Reg64("rax")))
        }
        _ => self.codegen_expr(value)
      }
    TypeDecl(name, fields) => {
      let field_names = fields.map(fn(f) { f.0 })
      let sf = self.struct_fields
      sf[name] = field_names
      { ..self, struct_fields: sf }
    }
    EnumDef(name, variants) => {
      let ed = self.enum_discriminants
      let mut i = 0
      while i < variants.length() {
        ed[variants[i]] = i
        i = i + 1
      }
      { ..self, enum_discriminants: ed }
    }
    StructLit(type_name, fields) => {
      let num_fields = fields.length()
      if num_fields == 0 {
        self.emit_inst(Mov(Reg64("rax"), Imm32(0)))
      } else {
        let mut g = self
        // Evaluate all field values and push onto stack (in reverse order)
        // Push field N-1 first (goes to highest address)
        // Push field 0 last (goes to lowest address)
        // After pushing: field 0 is at rsp, field 1 is at rsp + 8, etc.
        let mut i = num_fields - 1
        while i >= 0 {
          let (_fname, fval) = fields[i]
          g = g.codegen_expr(fval)
          g = g.emit_inst(Push(Reg64("rax")))
          // Do NOT update next_offset here - LetBind will calculate the correct offset
          i = i - 1
        }
        // After pushing N values, rsp points to field 0
        // The struct is now on the stack, no need to put anything in rax
        g
      }
    }
    StructUpdate(base, updates) =>
      // Functional update: { ..point, x: 20 }
      // Copy all fields from base, then update specified fields
      match base {
        Ident(var_name) =>
          match self.var_offsets.get(var_name) {
            Some(base_offset) => {
              let num_fields = match self.var_struct_fields.get(var_name) {
                Some(fields) => fields.length()
                None =>
                  match self.var_types.get(var_name) {
                    Some(type_name) =>
                      match self.struct_fields.get(type_name) {
                        Some(fields) => fields.length()
                        None => 0
                      }
                    None => 0
                  }
              }
              let field_names = match self.var_struct_fields.get(var_name) {
                Some(fields) => fields
                None =>
                  match self.var_types.get(var_name) {
                    Some(type_name) =>
                      match self.struct_fields.get(type_name) {
                        Some(fields) => fields
                        None => []
                      }
                    None => []
                  }
              }
              let mut g = self
              // Push all fields from base struct (in reverse order)
              let mut i = num_fields - 1
              while i >= 0 {
                let field_offset = base_offset + i * 8
                // Check if this field is being updated
                let mut is_updated = false
                let mut update_val : AST = Unit
                let mut k = 0
                while k < updates.length() {
                  let (fname, fval) = updates[k]
                  if fname == field_names[i] {
                    is_updated = true
                    update_val = fval
                  }
                  k = k + 1
                }
                if is_updated {
                  // Use the updated value
                  g = g.codegen_expr(update_val)
                  g = g.emit_inst(Push(Reg64("rax")))
                } else {
                  // Copy from base struct
                  g = g.emit_inst(Mov(Reg64("rax"), StackBP64(field_offset)))
                  g = g.emit_inst(Push(Reg64("rax")))
                }
                i = i - 1
              }
              g
            }
            None => self.emit_inst(Mov(Reg64("rax"), Imm32(0)))
          }
        _ => self.emit_inst(Mov(Reg64("rax"), Imm32(0)))
      }
    TestBlock(name, body) => {
      let mut g = self
      g = g.codegen_expr(body)
      g
    }
    _ => self
  }
}

///|
fn CodeGen::codegen_func(
  self : CodeGen,
  name : String,
  params : Array[(String, AST?)],
  body : AST,
) -> CodeGen {
  let arg_regs = ["rdi", "rsi", "rdx", "rcx", "r8", "r9"]
  let mut g = self
  g = g.define_label("\{name}")
  g = g.emit_inst(Push(Reg64("rbp")))
  g = g.emit_inst(Mov(Reg64("rbp"), Reg64("rsp")))
  // Reset var_offsets for this function
  g = { ..g, var_offsets: Map::new(), next_offset: -8 }
  // Save parameters to stack and add to var_offsets
  // Push in forward order so first param is at rbp-8
  let mut i = 0
  while i < params.length() {
    if i < 6 {
      g = g.emit_inst(Push(Reg64(arg_regs[i])))
    }
    i = i + 1
  }
  // Record offsets: first param at rbp-8, second at rbp-16, etc.
  let mut j = 0
  while j < params.length() {
    let (param_name, _) = params[j]
    if j < 6 {
      let offset = -8 - j * 8
      let new_offsets = g.var_offsets
      new_offsets[param_name] = offset
      g = { ..g, var_offsets: new_offsets }
    }
    j = j + 1
  }
  g = { ..g, next_offset: -8 - params.length() * 8 }
  g = g.codegen_expr(body)
  // Restore stack frame: mov rsp, rbp; pop rbp; ret
  g = g.emit_inst(Mov(Reg64("rsp"), Reg64("rbp")))
  g = g.emit_inst(Pop(Reg64("rbp")))
  g = g.emit_inst(Ret)
  g
}

///|
fn collect_funcs(
  ast : AST,
  funcs : Map[String, (Array[(String, AST?)], AST)],
) -> Map[String, (Array[(String, AST?)], AST)] {
  match ast {
    Func(name, params, _ret, body) => {
      if name != "main" {
        funcs[name] = (params, body)
      }
      collect_funcs(body, funcs)
    }
    Block(stmts) => {
      let mut f = funcs
      for stmt in stmts {
        f = collect_funcs(stmt, f)
      }
      f
    }
    LetBind(_, _, value, body) => {
      let f = collect_funcs(value, funcs)
      collect_funcs(body, f)
    }
    IfExpr(cond, then, else_opt) => {
      let f = collect_funcs(cond, funcs)
      let f = collect_funcs(then, f)
      match else_opt {
        Some(e) => collect_funcs(e, f)
        None => f
      }
    }
    Binary(_, left, right) => {
      let f = collect_funcs(left, funcs)
      collect_funcs(right, f)
    }
    Unary(_, e) => collect_funcs(e, funcs)
    CallExpr(func, args) => {
      let mut f = collect_funcs(func, funcs)
      for arg in args {
        f = collect_funcs(arg, f)
      }
      f
    }
    ReturnExpr(e) => collect_funcs(e, funcs)
    WhileLoop(cond, body) => {
      let f = collect_funcs(cond, funcs)
      collect_funcs(body, f)
    }
    ForLoop(init, cond, step, body) => {
      let mut f = funcs
      match init {
        Some(i) => f = collect_funcs(i, f)
        None => ()
      }
      match cond {
        Some(c) => f = collect_funcs(c, f)
        None => ()
      }
      match step {
        Some(s) => f = collect_funcs(s, f)
        None => ()
      }
      collect_funcs(body, f)
    }
    _ => funcs
  }
}

///|
pub fn codegen(ast : AST) -> Bytes {
  // Collect all functions
  let all_funcs = collect_funcs(ast, Map::new())

  let mut g = CodeGen::new()
  g = { ..g, code: g.code + [0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90] }
  g = g.define_label("main")
  g = g.emit_inst(Push(Reg64("rbp")))
  g = g.emit_inst(Mov(Reg64("rbp"), Reg64("rsp")))
  g = g.codegen_expr(ast)
  g = g.define_label(".main_end")
  // Use return value as exit code (move rax to rdi)
  g = g.emit_inst(Mov(Reg64("rdi"), Reg64("rax")))
  g = g.emit_inst(Mov(Reg64("rax"), Imm32(60)))
  g = g.emit_inst(Mov(Reg64("rsp"), Reg64("rbp")))
  g = g.emit_inst(Pop(Reg64("rbp")))
  g = g.emit_inst(Syscall)

  // Emit all collected functions
  for name in all_funcs.keys() {
    let (params, body) = all_funcs[name]
    g = g.codegen_func(name, params, body)
  }

  let mut str_idx = 0
  while str_idx < g.strings.length() {
    let s = g.strings[str_idx]
    let label = ".Lstr\{str_idx}"
    g = g.define_label(label)
    let mut i = 0
    while i < s.length() {
      let ch = s[i]
      g = g.emit_byte(ch.to_int().reinterpret_as_uint().to_byte())
      i = i + 1
    }
    g = g.emit_byte(0)
    str_idx = str_idx + 1
  }
  // Map printing strings
  g = g.define_label(".Lmap_open")
  g = g.emit_byte(123) // {
  g = g.define_label(".Lmap_count")
  g = g.emit_bytes([99, 111, 117, 110, 116, 58, 32, 0]) // "count: \0"
  g = g.define_label(".Lmap_close")
  g = g.emit_byte(125) // }
  g = g.define_label(".Lmap_colon")
  g = g.emit_byte(58) // :
  g = g.emit_byte(32) // space
  g = g.define_label(".Lmap_comma")
  g = g.emit_byte(44) // ,
  g = g.emit_byte(32) // space
  g = g.define_label(".Lmap_val_placeholder")
  g = g.emit_byte(42) // *
  g = g.define_label(".Ldebug")
  g = g.emit_bytes([100, 101, 98, 117, 103, 10, 0]) // "debug\n\0"
  g = g.define_label(".Lmap_placeholder")
  g = g.emit_bytes([60, 109, 97, 112, 62, 0]) // "<map>\0"
  let mut flt_idx = 0
  while flt_idx < g.floats.length() {
    let f = g.floats[flt_idx]
    let label = ".Lflt\{flt_idx}"
    g = g.define_label(label)
    let bits = f.reinterpret_as_uint64()
    let b0 = (bits & 0xFF).to_byte()
    let b1 = ((bits >> 8) & 0xFF).to_byte()
    let b2 = ((bits >> 16) & 0xFF).to_byte()
    let b3 = ((bits >> 24) & 0xFF).to_byte()
    let b4 = ((bits >> 32) & 0xFF).to_byte()
    let b5 = ((bits >> 40) & 0xFF).to_byte()
    let b6 = ((bits >> 48) & 0xFF).to_byte()
    let b7 = ((bits >> 56) & 0xFF).to_byte()
    g = g.emit_byte(b0)
    g = g.emit_byte(b1)
    g = g.emit_byte(b2)
    g = g.emit_byte(b3)
    g = g.emit_byte(b4)
    g = g.emit_byte(b5)
    g = g.emit_byte(b6)
    g = g.emit_byte(b7)
    flt_idx = flt_idx + 1
  }
  // Emit buffers (smaller sizes for simple programs)
  g = g.define_label(".Linput_buf")
  g = g.emit_bytes(Array::make(256, 0x00))
  g = g.define_label(".Lint_buf")
  g = g.emit_bytes(Array::make(32, 0x00))
  g = g.define_label(".Lstrcat_buf")
  g = g.emit_bytes(Array::make(512, 0x00))
  g = g.define_label(".Lflt_buf")
  g = g.emit_bytes(Array::make(64, 0x00))
  g = g.define_label(".Larray_alloc_offset")
  g = g.emit_bytes(Array::make(8, 0x00))
  g = g.define_label(".Larrcat_buf")
  // Reduced from 819200 to 4096 - enough for simple programs
  g = g.emit_bytes(Array::make(4096, 0x00))
  // Map buffer: stores key-value pairs for map literals
  // Each entry: 8 bytes key pointer + 8 bytes value = 16 bytes
  // Support up to 64 entries (1KB total)
  g = g.define_label(".Lmap_buf")
  g = g.emit_bytes(Array::make(1024, 0x00))
  // Enum buffer: stores enum data (discriminant + fields)
  // 64KB total, each RGB takes 32 bytes (1 + 3 args), ~2000 enums max
  g = g.define_label(".Lenum_buf")
  g = g.emit_bytes(Array::make(65536, 0x00))
  let code = g.code
  let mut i = 0
  while i < g.pending_labels.length() {
    let (label_name, ref_pos) = g.pending_labels[i]
    match g.labels.get(label_name) {
      Some(target_pos) => {
        let offset = target_pos - (ref_pos + 4)
        let b0 = (offset.reinterpret_as_uint() & 0xFF).to_byte()
        let b1 = ((offset.reinterpret_as_uint() >> 8) & 0xFF).to_byte()
        let b2 = ((offset.reinterpret_as_uint() >> 16) & 0xFF).to_byte()
        let b3 = ((offset.reinterpret_as_uint() >> 24) & 0xFF).to_byte()
        code[ref_pos] = b0
        code[ref_pos + 1] = b1
        code[ref_pos + 2] = b2
        code[ref_pos + 3] = b3
      }
      None => ()
    }
    i = i + 1
  }
  Bytes::from_array(code)
}
