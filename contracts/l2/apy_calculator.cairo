%builtins output 

from starkware.cairo.common.serialize import serialize_word, serialize_array, array_rfold
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.keccak import unsafe_keccak
struct Allocation: 
    member strategy : felt
    member debt_ratio : felt
end

func main{output_ptr : felt*}():
    alloc_locals

    let (local inputs_array : felt*) = alloc()
    assert inputs_array[0] = 1
    assert inputs_array[1] = 2
    assert inputs_array[2] = 3
    let (a, b) = unsafe_keccak(inputs_array, 41)
    serialize_word(a)
    serialize_word(b)
    serialize_word(7600)
    serialize_word(2)
    let output = cast(output_ptr, Allocation*)

    let (local struct_array : Allocation*) = alloc()
    assert struct_array[0] = Allocation(strategy=0x194E22F49BC3f58903866d55488E1e9e8d69b517, debt_ratio=5000)
    assert struct_array[1] = Allocation(strategy=0xd5c325D183C592C94998000C5e0EED9e6655c020, debt_ratio=5000)
    
    assert [output] = struct_array[0]
    assert [output+2] = struct_array[1]
    let output_ptr = output_ptr + Allocation.SIZE * 2
    return()
end
