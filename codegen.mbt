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
  Call(String)
  Ret
  Nop
  Syscall
} derive(Show)

///|
pub enum X86Operand {
  Imm8(Int)
  Imm32(Int)
  Imm64(Int)
  Reg8(String)
  Reg32(String)
  Reg64(String)
  Stack8(Int)
  Stack32(Int)
  Stack64(Int)
  RipRel32(String)
  Label(String)
} derive(Show)

///|
pub struct CodeGen {
  code : Array[Byte]
  labels : Map[String, Int]
  pending_labels : Array[(String, Int)]
  label_counter : Int
  var_offsets : Map[String, Int]
  next_offset : Int
  current_func : String?
}

///|
fn CodeGen::new() -> CodeGen {
  {
    code: [],
    labels: Map::new(),
    pending_labels: [],
    label_counter: 0,
    var_offsets: Map::new(),
    next_offset: -8,
    current_func: None,
  }
}

///|
fn CodeGen::emit_byte(self : CodeGen, b : Byte) -> CodeGen {
  { ..self, code: self.code + [b] }
}

///|
fn CodeGen::emit_bytes(self : CodeGen, bytes : Array[Byte]) -> CodeGen {
  let mut g = self
  for b in bytes {
    g = g.emit_byte(b)
  }
  g
}

///|
fn CodeGen::emit32(self : CodeGen, v : Int) -> CodeGen {
  let b0 = (v.to_uint() & 0xFF).to_byte()
  let b1 = ((v.to_uint() >> 8) & 0xFF).to_byte()
  let b2 = ((v.to_uint() >> 16) & 0xFF).to_byte()
  let b3 = ((v.to_uint() >> 24) & 0xFF).to_byte()
  let g = self.emit_byte(b0).emit_byte(b1).emit_byte(b2).emit_byte(b3)
  g
}

///|
fn CodeGen::emit64(self : CodeGen, v : Int) -> CodeGen {
  let mut g = self
  let mut i = 0
  while i < 8 {
    let b = ((v.to_uint() >> (i * 8)) & 0xFF).to_byte()
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
    RipRel32(label) => self.emit32(0)
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
    Reg64("rbp") => self.emit_byte(modrm(3, reg_code, 5))
    Reg64("rsi") => self.emit_byte(modrm(3, reg_code, 6))
    Reg64("rdi") => self.emit_byte(modrm(3, reg_code, 7))
    Reg64("r8") => self.emit_bytes([0x44, modrm(3, reg_code, 0)])
    Reg64("r9") => self.emit_bytes([0x44, modrm(3, reg_code, 1)])
    Reg64("r10") => self.emit_bytes([0x44, modrm(3, reg_code, 2)])
    Reg64("r11") => self.emit_bytes([0x44, modrm(3, reg_code, 3)])
    Reg64("r12") => self.emit_bytes([0x44, modrm(3, reg_code, 4)])
    Reg64("r13") => self.emit_bytes([0x44, modrm(3, reg_code, 5)])
    Reg64("r14") => self.emit_bytes([0x44, modrm(3, reg_code, 6)])
    Reg64("r15") => self.emit_bytes([0x44, modrm(3, reg_code, 7)])
    Stack64(offset) => {
      let g = self.emit_byte(modrm(2, reg_code, 4))
      let g = g.emit_byte(sib(0, 4, 5))
      g.emit32(offset)
    }
    _ => self
  }
}

///|
fn CodeGen::emit_rex(
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
    Mov(Reg64(dest), Imm32(v)) => {
      let g = self.emit_operand64(Reg64(dest))
      g.emit32(v)
    }
    Mov(Reg64(dest), Imm64(v)) => {
      let g = self.emit_operand64(Reg64(dest))
      g.emit64(v)
    }
    Mov(Reg64(dest), Reg64(src)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x89)
      let g = g.emit_modrm_reg64(src, Reg64(dest))
      g
    }
    Mov(Reg64(dest), Stack64(offset)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x8B)
      let g = g.emit_modrm_reg64(dest, Stack64(offset))
      g
    }
    Mov(Stack64(offset), Reg64(src)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x89)
      let g = g.emit_modrm_reg64(src, Stack64(offset))
      g
    }
    Add(Reg64(dest), Reg64(src)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x01)
      let g = g.emit_modrm_reg64(src, Reg64(dest))
      g
    }
    Add(Reg64(dest), Imm32(v)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x81)
      let g = g.emit_modrm_reg64(dest, Reg64(dest))
      g.emit32(v)
    }
    Sub(Reg64(dest), Reg64(src)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x29)
      let g = g.emit_modrm_reg64(src, Reg64(dest))
      g
    }
    Sub(Reg64(dest), Imm32(v)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x81)
      let g = g.emit_modrm_reg64(dest, Reg64(dest))
      g.emit32(v)
    }
    Imul(Reg64(dest), Reg64(src)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x0F)
      let g = g.emit_byte(0xAF)
      let g = g.emit_modrm_reg64(src, Reg64(dest))
      g
    }
    Idiv(Reg64(src)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0xF7)
      let g = g.emit_modrm_reg64("rax", Reg64(src))
      g
    }
    Cmp(Reg64(dest), Reg64(src)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x39)
      let g = g.emit_modrm_reg64(src, Reg64(dest))
      g
    }
    Cmp(Reg64(dest), Imm32(v)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x81)
      let g = g.emit_modrm_reg64(dest, Reg64(dest))
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
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x81)
      let g = g.emit_modrm_reg64(dest, Reg64(dest))
      g.emit32(v)
    }
    Or(Reg64(dest), Reg64(src)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x09)
      let g = g.emit_modrm_reg64(src, Reg64(dest))
      g
    }
    Or(Reg64(dest), Imm32(v)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x81)
      let g = g.emit_modrm_reg64(dest, Reg64(dest))
      g.emit32(v)
    }
    Xor(Reg64(dest), Reg64(src)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x31)
      let g = g.emit_modrm_reg64(src, Reg64(dest))
      g
    }
    Xor(Reg64(dest), Imm32(v)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x81)
      let g = g.emit_modrm_reg64(dest, Reg64(dest))
      g.emit32(v)
    }
    Not(Reg64(dest)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0xF7)
      let g = g.emit_modrm_reg64("rax", Reg64(dest))
      g
    }
    Neg(Reg64(dest)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0xF7)
      let g = g.emit_modrm_reg64("rax", Reg64(dest))
      g
    }
    Shl(Reg64(dest), Imm8(1)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0xD1)
      let g = g.emit_modrm_reg64("rcx", Reg64(dest))
      g
    }
    Shl(Reg64(dest), Imm8(v)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0xC1)
      let g = g.emit_modrm_reg64("rcx", Reg64(dest))
      g.emit_byte(v.to_byte())
    }
    Shr(Reg64(dest), Imm8(1)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0xD1)
      let g = g.emit_modrm_reg64("rcx", Reg64(dest))
      g
    }
    Sar(Reg64(dest), Imm8(1)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0xD1)
      let g = g.emit_modrm_reg64("rcx", Reg64(dest))
      g
    }
    Jmp(_label) => {
      let g = self.emit_byte(0xE9)
      g.emit32(0)
    }
    Je(_label) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x84)
      g.emit32(0)
    }
    Jne(_label) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x85)
      g.emit32(0)
    }
    Jg(_label) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x8F)
      g.emit32(0)
    }
    Jge(_label) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x8D)
      g.emit32(0)
    }
    Jl(_label) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x8C)
      g.emit32(0)
    }
    Jle(_label) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x8E)
      g.emit32(0)
    }
    Ja(_label) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x87)
      g.emit32(0)
    }
    Jae(_label) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x83)
      g.emit32(0)
    }
    Jb(_label) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x82)
      g.emit32(0)
    }
    Jbe(_label) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x86)
      g.emit32(0)
    }
    Jz(_label) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x84)
      g.emit32(0)
    }
    Jnz(_label) => {
      let g = self.emit_byte(0x0F)
      let g = g.emit_byte(0x85)
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
    Call(_label) => {
      let g = self.emit_byte(0xE8)
      g.emit32(0)
    }
    _ => self
  }
}

///|
pub fn codegen(_ast : AST) -> Bytes {
  let g = CodeGen::new()
  let g = g.emit_inst(Mov(Reg64("rax"), Imm32(60)))
  let g = g.emit_inst(Mov(Reg64("rdi"), Imm32(0)))
  let g = g.emit_inst(Syscall)
  Bytes::from_array(g.code)
}
