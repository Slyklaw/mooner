///|
pub fn compile_file(
  input_path : String,
  output_path : String,
) -> Result[Unit, String] {
  // Read input file
  let source = @fs.read_file_to_string(input_path) catch {
    e => return Err("Failed to read input file: \{e}")
  }

  // Tokenize
  let tokens = tokenize(source)

  // Parse into AST
  let ast = parse(tokens)

  // Type check
  let checker = TypeChecker::new()
  let (checker, _) = checker.check(ast)

  if checker.errors.length() > 0 {
    let mut err_msg = ""
    for err in checker.errors {
      err_msg = err_msg + err.message + "\n"
    }
    return Err("Type errors:\n\{err_msg}")
  }

  // Generate x86_64 code
  let code = codegen(ast)

  // Header is 64 + 56 = 120 bytes (0x78)
  // Code should start at 0x401000 (like GCC -nostdlib -s)
  // File offset for code: 0x1000
  // Padding: 0x1000 - 0x78 = 0xF88 bytes
  let padding_len = 0x1000 - 0x78
  let padding : Array[Byte] = {
    let mut arr : Array[Byte] = []
    for _ in 0..<padding_len {
      arr = arr + [0x00B] // padding byte
    }
    arr
  }

  let header : Array[Byte] = [
    // ELF header (64 bytes)
    0x7F, 0x45, 0x4C, 0x46, // magic
     0x02, // 64-bit
     0x01, // little endian
     0x01, // version
     0x00, // SYS V ABI
     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // padding
     0x02, 0x00, // e_type = ET_EXEC
     0x3E, 0x00, // e_machine = x86-64
     0x01, 0x00, 0x00, 0x00, // e_version
     0x00, 0x10, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, // e_entry = 0x401000
     0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // e_phoff = 64
     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // e_shoff = 0
     0x00, 0x00, 0x00, 0x00, // e_flags
     0x40, 0x00, // e_ehsize = 64
     0x38, 0x00, // e_phentsize = 56
     0x01, 0x00, // e_phnum = 1
     0x00, 0x00, // e_shentsize
     0x00, 0x00, // e_shnum
     0x00, 0x00, // e_shstrndx

    // Program header (56 bytes)
     0x01, 0x00, 0x00, 0x00, // p_type = PT_LOAD
     0x05, 0x00, 0x00, 0x00, // p_flags = PF_X | PF_R
     0x00, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // p_offset = 0x1000
     0x00, 0x10, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, // p_vaddr = 0x401000
     0x00, 0x10, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, // p_paddr = 0x401000
  ]

  // Calculate code size
  let code_len = code.length()
  let padded_code_len = (code_len + 0xFFF) & 0xFFFFF000

  let phdr_filesz : Array[Byte] = [
    (padded_code_len & 0xFF).to_byte(),
    ((padded_code_len >> 8) & 0xFF).to_byte(),
    ((padded_code_len >> 16) & 0xFF).to_byte(),
    ((padded_code_len >> 24) & 0xFF).to_byte(),
    ((padded_code_len >> 32) & 0xFF).to_byte(),
    ((padded_code_len >> 40) & 0xFF).to_byte(),
    ((padded_code_len >> 48) & 0xFF).to_byte(),
    ((padded_code_len >> 56) & 0xFF).to_byte(),
  ]

  let phdr_memsz = phdr_filesz

  let phdr_align : Array[Byte] = [
    0x00, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // p_align = 0x1000
  ]

  let header_bytes = Bytes::from_array(header)
  let phdr_bytes = Bytes::from_array(phdr_filesz + phdr_memsz + phdr_align)
  let padding_bytes = Bytes::from_array(padding)
  let code_bytes = code

  let result = header_bytes + phdr_bytes + padding_bytes + code_bytes

  try {
    @fs.write_bytes_to_file(output_path, result)
    Ok(())
  } catch {
    e => Err("Failed to write output file: \{e}")
  }
}
