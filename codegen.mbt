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
  Cvtsd2si(X86Operand, X86Operand)
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
} derive(Show)

///|
pub struct CodeGen {
  code : Array[Byte]
  labels : Map[String, Int]
  pending_labels : Array[(String, Int)]
  label_counter : Int
  var_offsets : Map[String, Int]
  var_is_float : Map[String, Bool]
  next_offset : Int
  current_func : String?
  func_bodies : Map[String, AST]
  strings : Array[String]
  string_counter : Int
  floats : Array[Double]
  float_counter : Int
  loop_labels : Array[(String, String)]
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
    next_offset: -8,
    current_func: None,
    func_bodies: Map::new(),
    strings: [],
    string_counter: 0,
    floats: [],
    float_counter: 0,
    loop_labels: [],
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
    Mov(Reg64(dest), StackBP64(offset)) => {
      // mov reg64, [rbp+offset]
      let g = self.emit_byte(0x48) // REX.w
      let g = g.emit_byte(0x8B) // ModR/M for mov reg64, r/m64
      let g = g.emit_modrm_reg64(dest, StackBP64(offset))
      g
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
    Mov(Reg64(dest), MemIndirect(addr_reg)) => {
      // mov reg64, [addr_reg]
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
      // REX.W + 8B + ModRM (mod=00, reg=dest, rm=addr_reg)
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x8B)
      // mod=00 (indirect), reg=dest_code, rm=rm_code
      // But rsp and rbp need special handling
      if addr_reg == "rsp" {
        // Need SIB byte for rsp: mod=00, reg=dest, rm=100 (SIB), SIB=00,100,100
        let g = g.emit_byte(modrm(0, dest_code, 4))
        g.emit_byte(sib(0, 4, 4))
      } else if addr_reg == "rbp" {
        // rbp with mod=00 means disp32, so use mod=01 with disp8=0
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
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x81)
      if dest == "rsp" {
        let g = g.emit_byte(modrm(3, 0, 4))
        let g = g.emit_byte(sib(0, 4, 4))
        let b0 = (v.reinterpret_as_uint() & 0xFF).to_byte()
        let b1 = ((v.reinterpret_as_uint() >> 8) & 0xFF).to_byte()
        let b2 = ((v.reinterpret_as_uint() >> 16) & 0xFF).to_byte()
        let b3 = ((v.reinterpret_as_uint() >> 24) & 0xFF).to_byte()
        let g = g.emit_byte(b0)
        let g = g.emit_byte(b1)
        let g = g.emit_byte(b2)
        g.emit_byte(b3)
      } else {
        let g = g.emit_modrm_reg64(dest, Reg64(dest))
        let b0 = (v.reinterpret_as_uint() & 0xFF).to_byte()
        let b1 = ((v.reinterpret_as_uint() >> 8) & 0xFF).to_byte()
        let b2 = ((v.reinterpret_as_uint() >> 16) & 0xFF).to_byte()
        let b3 = ((v.reinterpret_as_uint() >> 24) & 0xFF).to_byte()
        let g = g.emit_byte(b0)
        let g = g.emit_byte(b1)
        let g = g.emit_byte(b2)
        g.emit_byte(b3)
      }
    }
    Sub(Reg64(dest), Reg64(src)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x29)
      let g = g.emit_modrm_reg64(src, Reg64(dest))
      g
    }
    Sub(Reg64(_dest), Imm32(v)) => {
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0x81)
      let modrm_byte = modrm(3, 5, 4) // reg=101 (sub), rm=100 (rsp with SIB)
      let g = g.emit_byte(modrm_byte)
      let g = g.emit_byte(sib(0, 4, 4)) // SIB: scale=0, index=4 (none), base=4 (rsp)
      let b0 = (v.reinterpret_as_uint() & 0xFF).to_byte()
      let b1 = ((v.reinterpret_as_uint() >> 8) & 0xFF).to_byte()
      let b2 = ((v.reinterpret_as_uint() >> 16) & 0xFF).to_byte()
      let b3 = ((v.reinterpret_as_uint() >> 24) & 0xFF).to_byte()
      let g = g.emit_byte(b0)
      let g = g.emit_byte(b1)
      let g = g.emit_byte(b2)
      g.emit_byte(b3)
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
      let g = self.emit_byte(0x48)
      let g = g.emit_byte(0xF7)
      // mod=11, reg=7 (idiv extension), rm=src_code
      let g = g.emit_byte(modrm(3, 7, src_code))
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
    Movsd(StackBP64(offset), Xmm(src)) => {
      let src_code = xmm_reg_code(src)
      let g = self.emit_bytes([0xF2, 0x0F, 0x11])
      let g = g.emit_byte(modrm(2, src_code, 5))
      g.emit32(offset)
    }
    Addsd(Xmm(dest), Xmm(src)) => {
      let g = self.emit_bytes([0xF2, 0x0F, 0x58])
      let dest_code = xmm_reg_code(dest)
      let src_code = xmm_reg_code(src)
      g.emit_byte(modrm(3, src_code, dest_code))
    }
    Subsd(Xmm(dest), Xmm(src)) => {
      let g = self.emit_bytes([0xF2, 0x0F, 0x5C])
      let dest_code = xmm_reg_code(dest)
      let src_code = xmm_reg_code(src)
      g.emit_byte(modrm(3, src_code, dest_code))
    }
    Mulsd(Xmm(dest), Xmm(src)) => {
      let g = self.emit_bytes([0xF2, 0x0F, 0x59])
      let dest_code = xmm_reg_code(dest)
      let src_code = xmm_reg_code(src)
      g.emit_byte(modrm(3, src_code, dest_code))
    }
    Divsd(Xmm(dest), Xmm(src)) => {
      let g = self.emit_bytes([0xF2, 0x0F, 0x5E])
      let dest_code = xmm_reg_code(dest)
      let src_code = xmm_reg_code(src)
      g.emit_byte(modrm(3, src_code, dest_code))
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
    Cvtsd2si(Reg64(dest), Xmm(src)) => {
      let g = self.emit_bytes([0xF2, 0x48, 0x0F, 0x2D])
      let dest_code = reg_code(dest)
      let src_code = xmm_reg_code(src)
      g.emit_byte(modrm(3, dest_code, src_code))
    }
    _ => self
  }
}

///|
fn CodeGen::add_string(self : CodeGen, s : String) -> (CodeGen, String) {
  let label = ".Lstr\{self.string_counter}"
  let g = {
    ..self,
    string_counter: self.string_counter + 1,
    strings: self.strings + [s],
  }
  (g, label)
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
    _ => false
  }
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
      let g = self.emit_inst(Mov(Reg64("rax"), Imm32(s.length())))
      g
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
          } else {
            let g = self.emit_inst(Mov(Reg64("rax"), StackBP64(offset)))
            g
          }
        None => {
          let g = self.emit_inst(Mov(Reg64("rax"), Imm32(0)))
          g
        }
      }
    Binary(op, left, right) => {
      let is_float = is_float_expr(left, self.var_is_float) ||
        is_float_expr(right, self.var_is_float)
      if is_float {
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
    CallExpr(func, args) => {
      let func_name = match func {
        Ident(name) => name
        _ => ""
      }
      match func_name {
        "println" | "print" => {
          let is_println = func_name == "println"
          let mut g = self
          let mut arg_idx = 0
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
              _ => {
                let is_float = is_float_expr(arg, g.var_is_float)
                if is_float {
                  let (g2, label) = g.add_string("<float>")
                  g = g2
                  g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(label)))
                  g = g.emit_inst(Mov(Reg64("rdx"), Imm32(7)))
                } else {
                  let (g2, label) = g.add_string("<value>")
                  g = g2
                  g = g.emit_inst(Lea(Reg64("rsi"), RipRel32(label)))
                  g = g.emit_inst(Mov(Reg64("rdx"), Imm32(7)))
                }
              }
            }
            g = g.emit_inst(Mov(Reg64("rax"), Imm32(1)))
            g = g.emit_inst(Mov(Reg64("rdi"), Imm32(1)))
            g = g.emit_inst(Syscall)
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
          g = g.emit_inst(Lea(Reg64("rax"), RipRel32(label)))
          g
        }
        _ => {
          // User-defined function call
          // System V AMD64 ABI: rdi, rsi, rdx, rcx, r8, r9 for first 6 args
          let arg_regs = ["rdi", "rsi", "rdx", "rcx", "r8", "r9"]
          let mut g = self
          // Evaluate args and push to stack (in reverse for stack args)
          // First pass: evaluate all args, store results on stack
          let num_args = args.length()
          let mut i = num_args - 1
          while i >= 0 {
            g = g.codegen_expr(args[i])
            g = g.emit_inst(Push(Reg64("rax")))
            i = i - 1
          }
          // Pop args into registers (first 6) and leave rest on stack
          let mut j = 0
          while j < num_args {
            if j < 6 {
              g = g.emit_inst(Pop(Reg64(arg_regs[j])))
            }
            j = j + 1
          }
          // Call the function
          g = g.emit_inst(Call(func_name))
          // Clean up stack args if any (args beyond 6)
          if num_args > 6 {
            let cleanup = (num_args - 6) * 8
            g = g.emit_inst(Add(Reg64("rsp"), Imm32(cleanup)))
          }
          g
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
      // Allocate array on stack by pushing elements
      // Elements are pushed in reverse order so index 0 is at lowest address
      // Result: rax = rbp-relative offset of first element
      let num_elems = elems.length()
      if num_elems == 0 {
        // Empty array: return 0 offset
        self.emit_inst(Mov(Reg64("rax"), Imm32(0)))
      } else {
        let array_size = num_elems * 8
        let first_elem_offset = self.next_offset - array_size
        let mut g = { ..self, next_offset: first_elem_offset }
        // Push elements in reverse order (so index 0 ends up at lowest address)
        let mut i = num_elems - 1
        while i >= 0 {
          g = g.codegen_expr(elems[i])
          g = g.emit_inst(Push(Reg64("rax")))
          i = i - 1
        }
        // After all pushes, rsp points to first element
        // Return the rbp-relative offset of the first element
        // We compute: offset = rsp - rbp (this will be negative)
        // mov rax, rsp; sub rax, rbp
        let g = g.emit_inst(Mov(Reg64("rax"), Reg64("rsp")))
        let g = g.emit_inst(Sub(Reg64("rax"), Reg64("rbp")))
        g
      }
    }
    IndexExpr(arr, idx) => {
      // Array indexing: arr[idx]
      // arr evaluates to an rbp-relative offset of first element (lowest address)
      // Elements are at increasing addresses from there
      let g = self.codegen_expr(arr)
      // Save the offset
      let g = g.emit_inst(Push(Reg64("rax")))
      // Evaluate index
      let g = g.codegen_expr(idx)
      // Index is in rax, multiply by 8 for byte offset
      let g = g.emit_inst(Mov(Reg64("rcx"), Imm32(8)))
      let g = g.emit_inst(Imul(Reg64("rax"), Reg64("rcx")))
      // rax = index * 8
      // Pop array offset into rcx
      let g = g.emit_inst(Pop(Reg64("rcx")))
      // Add offset: rcx = base_offset + index*8
      let g = g.emit_inst(Add(Reg64("rcx"), Reg64("rax")))
      // Now rcx contains the rbp-relative offset of the element
      // Compute absolute address: rbx = rbp + rcx
      let g = g.emit_inst(Push(Reg64("rbx")))
      let g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rbp")))
      let g = g.emit_inst(Add(Reg64("rbx"), Reg64("rcx")))
      // Load from [rbx]
      let g = g.emit_inst(Mov(Reg64("rax"), MemIndirect("rbx")))
      g.emit_inst(Pop(Reg64("rbx")))
    }
    Tuple(elems) => {
      // Allocate tuple on stack by pushing elements
      // Elements are pushed in reverse order so index 0 is at lowest address
      // Result: rax = rbp-relative offset of first element
      let num_elems = elems.length()
      if num_elems == 0 {
        // Empty tuple: return 0 offset
        self.emit_inst(Mov(Reg64("rax"), Imm32(0)))
      } else {
        let tuple_size = num_elems * 8
        let first_elem_offset = self.next_offset - tuple_size
        let mut g = { ..self, next_offset: first_elem_offset }
        // Push elements in reverse order (so index 0 ends up at lowest address)
        let mut i = num_elems - 1
        while i >= 0 {
          g = g.codegen_expr(elems[i])
          g = g.emit_inst(Push(Reg64("rax")))
          i = i - 1
        }
        // After all pushes, rsp points to first element
        // Return the rbp-relative offset of the first element
        let g = g.emit_inst(Mov(Reg64("rax"), Reg64("rsp")))
        let g = g.emit_inst(Sub(Reg64("rax"), Reg64("rbp")))
        g
      }
    }
    FieldExpr(obj, field) => {
      // Tuple field access: obj.field where field is a numeric string
      // Elements are at increasing addresses from base: elem 0 at base, elem 1 at base+8, etc.
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
      // Evaluate the tuple expression (gives rbp-relative offset of element 0)
      let g = self.codegen_expr(obj)
      // Save the offset
      let g = g.emit_inst(Push(Reg64("rax")))
      // Compute index * 8
      let g = g.emit_inst(Mov(Reg64("rax"), Imm32(idx * 8)))
      // Pop tuple offset into rcx
      let g = g.emit_inst(Pop(Reg64("rcx")))
      // Add: rcx = base_offset + index*8
      let g = g.emit_inst(Add(Reg64("rcx"), Reg64("rax")))
      // Compute absolute address and load
      let g = g.emit_inst(Push(Reg64("rbx")))
      let g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rbp")))
      let g = g.emit_inst(Add(Reg64("rbx"), Reg64("rcx")))
      let g = g.emit_inst(Mov(Reg64("rax"), MemIndirect("rbx")))
      g.emit_inst(Pop(Reg64("rbx")))
    }
    LetBind(name, _annot, value, body) => {
      let is_float = is_float_expr(value, self.var_is_float)
      let g = self.codegen_expr(value)
      let g2 = if is_float {
        let g = g.emit_inst(PushXmm("xmm0"))
        g
      } else {
        g.emit_inst(Push(Reg64("rax")))
      }
      let offset = g2.next_offset
      let g3 = {
        let new_offsets = g2.var_offsets
        new_offsets[name] = offset
        let new_floats = g2.var_is_float
        new_floats[name] = is_float
        {
          ..g2,
          var_offsets: new_offsets,
          var_is_float: new_floats,
          next_offset: offset - 8,
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
      let (g, end_label) = self.new_label()
      // Evaluate the expression to match
      let mut g = g.codegen_expr(scrutinee)
      // Save scrutinee to rbx (callee-saved, preserved across function calls)
      // But first save rbx to stack
      g = g.emit_inst(Push(Reg64("rbx")))
      g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rax")))
      let num_cases = cases.length()
      let mut i = 0
      while i < num_cases {
        let (pattern, body) = cases[i]
        let (g2, next_label) = g.new_label()
        g = g2
        match pattern {
          Int(n) => {
            // Compare rbx (scrutinee) with literal n
            g = g.emit_inst(Mov(Reg64("rax"), Imm32(n)))
            g = g.emit_inst(Cmp(Reg64("rbx"), Reg64("rax")))
            g = g.emit_inst(Jne(next_label))
            // Matched: evaluate body
            g = g.codegen_expr(body)
            g = g.emit_inst(Jmp(end_label))
          }
          Bool(b) => {
            g = g.emit_inst(Mov(Reg64("rax"), Imm32(if b { 1 } else { 0 })))
            g = g.emit_inst(Cmp(Reg64("rbx"), Reg64("rax")))
            g = g.emit_inst(Jne(next_label))
            g = g.codegen_expr(body)
            g = g.emit_inst(Jmp(end_label))
          }
          Ident("_") => {
            // Wildcard always matches
            g = g.codegen_expr(body)
            g = g.emit_inst(Jmp(end_label))
          }
          Ident(name) => {
            // Variable binding: bind scrutinee value to name, then eval body
            // Push rbx (scrutinee) to create a binding
            g = g.emit_inst(Push(Reg64("rbx")))
            let offset = g.next_offset
            let new_offsets = g.var_offsets
            new_offsets[name] = offset
            g = { ..g, var_offsets: new_offsets, next_offset: offset - 8 }
            g = g.codegen_expr(body)
            // Pop the binding
            g = g.emit_inst(Add(Reg64("rsp"), Imm32(8)))
            g = g.emit_inst(Jmp(end_label))
          }
          _ =>
            // Unknown pattern: skip this case
            ()
        }
        g = g.define_label(next_label)
        i = i + 1
      }
      // Restore rbx
      g = g.emit_inst(Pop(Reg64("rbx")))
      g = g.define_label(end_label)
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
          // Array element assignment: arr[idx] = value
          let g = self.codegen_expr(arr)
          // Save the offset
          let g = g.emit_inst(Push(Reg64("rax")))
          // Evaluate index
          let g = g.codegen_expr(idx)
          // Multiply index by 8
          let g = g.emit_inst(Mov(Reg64("rcx"), Imm32(8)))
          let g = g.emit_inst(Imul(Reg64("rax"), Reg64("rcx")))
          // rax = index * 8
          // Pop array offset
          let g = g.emit_inst(Pop(Reg64("rcx")))
          // rcx = base_offset + index*8
          let g = g.emit_inst(Add(Reg64("rcx"), Reg64("rax")))
          // Evaluate value
          let g = g.codegen_expr(value)
          // Store value at [rbp + rcx]
          let g = g.emit_inst(Push(Reg64("rbx")))
          let g = g.emit_inst(Mov(Reg64("rbx"), Reg64("rbp")))
          let g = g.emit_inst(Add(Reg64("rbx"), Reg64("rcx")))
          let g = g.emit_inst(Mov(MemIndirect("rbx"), Reg64("rax")))
          g.emit_inst(Pop(Reg64("rbx")))
        }
        FieldExpr(obj, _field) =>
          // Field assignment: obj.field = value
          // For now, just evaluate the value (struct assignment not implemented)
          self.codegen_expr(value)
        _ =>
          // Unknown assignment target
          self.codegen_expr(value)
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
  g = g.define_label(".Linput_buf")
  let mut buf_idx = 0
  while buf_idx < 256 {
    g = g.emit_byte(0x00)
    buf_idx = buf_idx + 1
  }
  let code = g.code
  let mut i = 0
  while i < g.pending_labels.length() {
    let (label_name, ref_pos) = g.pending_labels[i]
    match g.labels.get(label_name) {
      Some(target_pos) => {
        // RIP-relative: offset from end of instruction (ref_pos + 4 bytes for displacement)
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
