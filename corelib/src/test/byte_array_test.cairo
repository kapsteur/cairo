use array::{ArrayTrait, SpanTrait};
use byte_array::ByteArrayTrait;
use bytes_31::Bytes31IntoFelt252;
use option::OptionTrait;
use traits::Into;

#[test]
#[available_gas(1000000)]
fn test_append_byte() {
    let mut ba = Default::default();
    let mut c = 1_u8;
    loop {
        if c == 34 {
            break;
        }
        ba.append_byte(c);
        c += 1;
    };

    let expected_data = array![0x0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f];
    compare_byte_array(@ba, expected_data.span(), 2, 0x2021);
}

#[test]
#[available_gas(1000000)]
fn test_append_word() {
    let mut ba = Default::default();

    ba.append_word(0x0102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e, 30);
    compare_byte_array(
        @ba, array![].span(), 30, 0x0102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e
    );

    ba.append_word(0x1f2021, 3);
    let expected_data = array![0x0102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e1f];
    compare_byte_array(@ba, expected_data.span(), 2, 0x2021);

    ba.append_word(0x2223, 2);
    compare_byte_array(@ba, expected_data.span(), 4, 0x20212223);

    // Length is 0, so nothing is actually appended.
    ba.append_word(0xffee, 0);
    compare_byte_array(@ba, expected_data.span(), 4, 0x20212223);

    ba.append_word(0x2425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e, 27);
    let expected_data = array![
        0x0102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e1f,
        0x202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e
    ];
    compare_byte_array(@ba, expected_data.span(), 0, 0);

    ba.append_word(0x3f, 1);
    compare_byte_array(@ba, expected_data.span(), 1, 0x3f);
}

#[test]
#[available_gas(1000000)]
fn test_append() {
    let mut ba1 = test_byte_array_32();
    let ba2 = test_byte_array_32();

    ba1.append(@ba2);

    let expected_data = array![
        0x0102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e1f,
        0x200102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e
    ];
    compare_byte_array(@ba1, expected_data.span(), 2, 0x1f20);
}

// Same as test_append, but with `+=` instead of `append`.
#[test]
#[available_gas(1000000)]
fn test_add_eq() {
    let mut ba1 = test_byte_array_32();
    let ba2 = test_byte_array_32();

    ba1 += ba2;

    let expected_data = array![
        0x0102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e1f,
        0x200102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e
    ];
    compare_byte_array(@ba1, expected_data.span(), 2, 0x1f20);
}

#[test]
#[available_gas(1000000)]
fn test_concat() {
    let ba1 = test_byte_array_32();
    let ba2 = test_byte_array_32();

    let ba3 = ByteArrayTrait::concat(@ba1, @ba2);

    let expected_data = array![
        0x0102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e1f,
        0x200102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e
    ];
    compare_byte_array(@ba3, expected_data.span(), 2, 0x1f20);
}

// Same as test_concat, but with `+` instead of `concat`.
#[test]
#[available_gas(1000000)]
fn test_add() {
    let ba1 = test_byte_array_32();
    let ba2 = test_byte_array_32();

    let ba3 = ba1 + ba2;

    let expected_data = array![
        0x0102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e1f,
        0x200102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e
    ];
    compare_byte_array(@ba3, expected_data.span(), 2, 0x1f20);
}

// Test concat/append, first byte array empty.
#[test]
#[available_gas(1000000)]
fn test_concat_first_empty() {
    let ba1 = Default::default();
    let ba2 = test_byte_array_32();

    let ba3 = ByteArrayTrait::concat(@ba1, @ba2);

    let expected_data = array![0x0102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e1f];
    compare_byte_array(@ba3, expected_data.span(), 1, 0x20);
}

// Test concat/append, second byte array empty.
#[test]
#[available_gas(1000000)]
fn test_concat_second_empty() {
    let ba1 = test_byte_array_32();
    let ba2 = Default::default();

    let ba3 = ByteArrayTrait::concat(@ba1, @ba2);

    let expected_data = array![0x0102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e1f];
    compare_byte_array(@ba3, expected_data.span(), 1, 0x20);
}

// Test concat/append, first byte array pending word is empty.
#[test]
#[available_gas(1000000)]
fn test_concat_first_pending_0() {
    let ba1 = test_byte_array_31();
    let ba2 = test_byte_array_32();

    let ba3 = ByteArrayTrait::concat(@ba1, @ba2);

    let expected_data = array![
        0x0102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e1f,
        0x0102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e1f
    ];
    compare_byte_array(@ba3, expected_data.span(), 1, 0x20);
}

// Test concat/append, second byte array pending word is empty.
#[test]
#[available_gas(1000000)]
fn test_concat_second_pending_0() {
    let ba1 = test_byte_array_32();
    let ba2 = test_byte_array_31();

    let ba3 = ByteArrayTrait::concat(@ba1, @ba2);

    let expected_data = array![
        0x0102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e1f,
        0x200102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e
    ];
    compare_byte_array(@ba3, expected_data.span(), 1, 0x1f);
}

// Test concat/append, split index of the words of the second byte array is 16.
#[test]
#[available_gas(1000000)]
fn test_concat_split_index_16() {
    let ba1 = test_byte_array_16();
    let ba2 = test_byte_array_32();

    let ba3 = ByteArrayTrait::concat(@ba1, @ba2);

    let expected_data = array![0x0102030405060708091a0b0c0d0e0f100102030405060708091a0b0c0d0e0f];
    compare_byte_array(@ba3, expected_data.span(), 17, 0x101112131415161718191a1b1c1d1e1f20);
}

// Test concat/append, split index of the words of the second byte array is < 16, specifically 1.
#[test]
#[available_gas(1000000)]
fn test_concat_split_index_lt_16() {
    let ba1 = test_byte_array_1();
    let ba2 = test_byte_array_32();

    let ba3 = ByteArrayTrait::concat(@ba1, @ba2);

    let expected_data = array![0x010102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e];
    compare_byte_array(@ba3, expected_data.span(), 2, 0x1f20);
}

// Test concat/append, split index of the words of the second byte array is > 16, specifically 30.
#[test]
#[available_gas(1000000)]
fn test_concat_split_index_gt_16() {
    let ba1 = test_byte_array_30();
    let ba2 = test_byte_array_33();

    let ba3 = ByteArrayTrait::concat(@ba1, @ba2);

    let expected_data = array![
        0x0102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e01,
        0x02030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20
    ];
    compare_byte_array(@ba3, expected_data.span(), 1, 0x21);
}

// Sum of the lengths of the pending words of both byte arrays is 31 (a full word).
#[test]
#[available_gas(1000000)]
fn test_concat_pending_sum_up_to_full() {
    let ba1 = test_byte_array_32();
    let ba2 = test_byte_array_30();

    let ba3 = ByteArrayTrait::concat(@ba1, @ba2);

    let expected_data = array![
        0x0102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e1f,
        0x200102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e
    ];
    compare_byte_array(@ba3, expected_data.span(), 0, 0);
}

// Sum of the lengths of the pending words of both byte arrays is 31+16.
// That is, the pending words aggregate to a full word, and the last split index is 16.
#[test]
#[available_gas(1000000)]
fn test_concat_pending_sum_up_to_more_than_word_16() {
    let ba1 = test_byte_array_17();
    let ba2 = test_byte_array_30();

    let ba3 = ByteArrayTrait::concat(@ba1, @ba2);

    let expected_data = array![0x0102030405060708091a0b0c0d0e0f10110102030405060708091a0b0c0d0e];
    compare_byte_array(@ba3, expected_data.span(), 16, 0x0f101112131415161718191a1b1c1d1e);
}

// Sum of the lengths of the pending words of both byte arrays is in [32, 31+15].
// That is, the pending words aggregate to a full word, and the last split index is <16.
#[test]
#[available_gas(1000000)]
fn test_concat_pending_sum_up_to_more_than_word_lt16() {
    let ba1 = test_byte_array_2();
    let ba2 = test_byte_array_30();

    let ba3 = ByteArrayTrait::concat(@ba1, @ba2);

    let expected_data = array![0x01020102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d];
    compare_byte_array(@ba3, expected_data.span(), 1, 0x1e);
}

// Sum of the lengths of the pending words of both byte arrays is >31+15
// That is, the pending words aggregate to a full word, and the last split index is >16.
#[test]
#[available_gas(1000000)]
fn test_concat_pending_sum_up_to_more_than_word_gt16() {
    let ba1 = test_byte_array_30();
    let ba2 = test_byte_array_30();

    let ba3 = ByteArrayTrait::concat(@ba1, @ba2);

    let expected_data = array![0x0102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e01];
    compare_byte_array(
        @ba3, expected_data.span(), 29, 0x02030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e
    );
}

// ========= Test helper functions =========

use debug::PrintTrait;
fn compare_byte_array(
    mut ba: @ByteArray, mut data: Span<felt252>, pending_word_len: usize, pending_word: felt252
) {
    assert(ba.data.len() == data.len(), 'wrong data len');
    let mut ba_data = ba.data.span();

    let mut data_index = 0;
    loop {
        match ba_data.pop_front() {
            Option::Some(x) => {
                let actual_word = (*x).into();
                let expected_word = *data.pop_front().unwrap();
                if actual_word != expected_word {
                    'data_index:'.print();
                    data_index.print();
                    'expected word:'.print();
                    expected_word.print();
                    'actual word:'.print();
                    actual_word.print();

                    panic_with_felt252('wrong data');
                }
            },
            Option::None(_) => {
                break;
            }
        }
        data_index += 1;
    };

    if *ba.pending_word_len != pending_word_len {
        'expected pending word len:'.print();
        pending_word_len.print();
        'actual pending word len:'.print();
        (*ba.pending_word_len).print();
        panic_with_felt252('wrong pending_word_len');
    }
    let ba_pending_word_felt: felt252 = (*ba.pending_word).into();
    if ba_pending_word_felt != pending_word {
        'expected pending word:'.print();
        pending_word.print();
        'actual pending word:'.print();
        ba_pending_word_felt.print();
        panic_with_felt252('wrong pending_word');
    }
}

fn test_byte_array_1() -> ByteArray {
    let mut ba1 = Default::default();
    ba1.append_word(0x01, 1);
    ba1
}

fn test_byte_array_2() -> ByteArray {
    let mut ba1 = Default::default();
    ba1.append_word(0x0102, 2);
    ba1
}

fn test_byte_array_16() -> ByteArray {
    let mut ba1 = Default::default();
    ba1.append_word(0x0102030405060708091a0b0c0d0e0f10, 16);
    ba1
}

fn test_byte_array_17() -> ByteArray {
    let mut ba1 = Default::default();
    ba1.append_word(0x0102030405060708091a0b0c0d0e0f1011, 17);
    ba1
}

fn test_byte_array_30() -> ByteArray {
    let mut ba1 = Default::default();
    ba1.append_word(0x0102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e, 30);
    ba1
}

fn test_byte_array_31() -> ByteArray {
    let mut ba1 = Default::default();
    ba1.append_word(0x0102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e1f, 31);
    ba1
}

fn test_byte_array_32() -> ByteArray {
    let mut ba1 = Default::default();
    ba1.append_word(0x0102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e1f, 31);
    ba1.append_word(0x20, 1);
    ba1
}

fn test_byte_array_33() -> ByteArray {
    let mut ba2 = Default::default();
    ba2.append_word(0x0102030405060708091a0b0c0d0e0f101112131415161718191a1b1c1d1e1f, 31);
    ba2.append_word(0x2021, 2);
    ba2
}
