use starknet::{
    eth_address::U256IntoEthAddress, EthAddress, secp256r1::Secp256r1Impl, SyscallResultTrait
};
use option::OptionTrait;
use traits::{Into, TryInto};
use starknet::secp256_trait::{
    recover_public_key, verify_eth_signature, Secp256PointTrait, Signature
};
use starknet::secp256r1::{Secp256r1Point, Secp256r1PointImpl};

#[test]
#[available_gas(100000000)]
fn test_secp256r1_recover_public_key() {
    let (msg_hash, signature, expected_public_key_x, expected_public_key_y, _) =
        get_message_and_signature();
    let public_key = recover_public_key::<Secp256r1Point>(msg_hash, signature).unwrap();
    let (x, y) = public_key.get_coordinates().unwrap_syscall();
    assert(expected_public_key_x == x, 'recover failed 1');
    assert(expected_public_key_y == y, 'recover failed 2');
}


/// Returns a golden valid message hash and its signature, for testing.
fn get_message_and_signature() -> (u256, Signature, u256, u256, EthAddress) {
    // msg = ""
    // public key: (0x04aaec73635726f213fb8a9e64da3b8632e41495a944d0045b522eba7240fad5,
    //              0x0087d9315798aaa3a5ba01775787ced05eaaf7b4e09fc81d6d1aa546e8365d525d)
    let msg_hash = 0xe3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855;
    let r = 0xb292a619339f6e567a305c951c0dcbcc42d16e47f219f9e98e76e09d8770b34a;
    let s = 0x177e60492c5a8242f76f07bfe3661bde59ec2a17ce5bd2dab2abebdf89a62e2;

    let (public_key_x, public_key_y) = (
        0x04aaec73635726f213fb8a9e64da3b8632e41495a944d0045b522eba7240fad5,
        0x0087d9315798aaa3a5ba01775787ced05eaaf7b4e09fc81d6d1aa546e8365d525d
    );
    let eth_address = 0x492882426e1cda979008bfaf874ff796eb3bb1c0_u256.into();

    (msg_hash, Signature { r, s, y_parity: true }, public_key_x, public_key_y, eth_address)
}

#[test]
#[available_gas(100000000)]
fn test_verify_eth_signature() {
    let (msg_hash, signature, expected_public_key_x, expected_public_key_y, eth_address) =
        get_message_and_signature();
    verify_eth_signature::<Secp256r1Point>(:msg_hash, :signature, :eth_address);
}

#[test]
#[should_panic(expected: ('Invalid signature',))]
#[available_gas(100000000)]
fn test_verify_eth_signature_wrong_eth_address() {
    let (msg_hash, signature, expected_public_key_x, expected_public_key_y, eth_address) =
        get_message_and_signature();
    let eth_address = (eth_address.into() + 1).try_into().unwrap();
    verify_eth_signature::<Secp256r1Point>(:msg_hash, :signature, :eth_address);
}

#[test]
#[should_panic(expected: ('Signature out of range',))]
#[available_gas(100000000)]
fn test_verify_eth_signature_overflowing_signature_r() {
    let (msg_hash, mut signature, expected_public_key_x, expected_public_key_y, eth_address) =
        get_message_and_signature();
    signature.r = Secp256r1Impl::get_curve_size() + 1;
    verify_eth_signature::<Secp256r1Point>(:msg_hash, :signature, :eth_address);
}

#[test]
#[should_panic(expected: ('Signature out of range',))]
#[available_gas(100000000)]
fn test_verify_eth_signature_overflowing_signature_s() {
    let (msg_hash, mut signature, expected_public_key_x, expected_public_key_y, eth_address) =
        get_message_and_signature();
    signature.s = Secp256r1Impl::get_curve_size() + 1;
    verify_eth_signature::<Secp256r1Point>(:msg_hash, :signature, :eth_address);
}
