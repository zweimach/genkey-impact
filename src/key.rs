use openssl::asn1::{Asn1Integer, Asn1Time};
use openssl::bn::BigNum;
use openssl::hash::MessageDigest;
use openssl::nid::Nid;
use openssl::pkcs12::Pkcs12;
use openssl::pkey::PKey;
use openssl::rsa::Rsa;
use openssl::x509::extension::SubjectKeyIdentifier;
use openssl::x509::{X509Name, X509};
use rand::Rng;
use serde::{Deserialize, Serialize};


#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Key {
    #[serde(rename = "npwp")]
    tax_id: String,
    company_name: String,
    email: String,
    password: String,
    location: Option<String>,
    province: Option<String>,
    validity: Option<u32>,
}

impl Key {
    pub fn to_pkcs12(&self) -> Vec<u8> {
        let mut rng = rand::thread_rng();

        let rsa = Rsa::generate(2048).expect("Generate RSA key failed");
        let pkey = PKey::from_rsa(rsa).expect("Generate key pair failed");

        let mut builder = X509Name::builder().expect("Get X509Name builder failed");
        let tax_id = self.tax_id.replace('.', "").replace('-', "");
        let timestamp = "202109241029"; // TODO
        let common_name = format!("{}-{}-{}", self.company_name, timestamp, tax_id);
        builder
            .append_entry_by_text("CN", &common_name)
            .expect("Set X509Name `CN` failed");
        let organizational_unit = "Jakarta"; // TODO
        builder
            .append_entry_by_text("OU", organizational_unit)
            .expect("Set X509Name `OU` failed");
        let organization = "OP"; // TODO
        builder
            .append_entry_by_text("O", organization)
            .expect("Set X509Name `O` failed");
        let location = "Jakarta".to_string();
        builder
            .append_entry_by_text("L", &self.location.clone().unwrap_or(location))
            .expect("Set X509Name `L` failed");
        let state = "DKI Jakarta".to_string();
        builder
            .append_entry_by_text("ST", &self.province.clone().unwrap_or(state))
            .expect("Set X509Name `ST` failed");
        let country = "ID"; // TODO
        builder
            .append_entry_by_text("C", country)
            .expect("Set X509Name `C` failed");
        builder
            .append_entry_by_nid(Nid::PKCS9_EMAILADDRESS, &self.email)
            .expect("Set X509Name `EMAILADDRESS` failed");
        let name = builder.build();

        let mut builder = X509::builder().expect("Get X509 builder failed");
        builder.set_version(2).expect("Set X509 version failed");
        builder.set_subject_name(&name).expect("Set X509 subject name failed");
        builder.set_issuer_name(&name).expect("Set X509 issuer name failed");
        builder.set_pubkey(&pkey).expect("Set X509 public key failed");
        let not_before = Asn1Time::from_str(&format!("{}Z", timestamp)).expect("Set Asn1Time before failed");
        builder.set_not_before(&not_before).expect("Set X509 start time failed");
        let not_after = Asn1Time::days_from_now(365).expect("Set Asn1Time after failed");
        builder.set_not_after(&not_after).expect("Set X509 validity failed");
        builder.sign(&pkey, MessageDigest::sha256()).expect("Sign X509 failed");
        let subject_key_id = SubjectKeyIdentifier::new()
            .build(&builder.x509v3_context(None, None))
            .expect("Generate SubjectKeyIdentifier failed");
        builder
            .append_extension(subject_key_id)
            .expect("Set X509 extension failed");
        let random_serial = &BigNum::from_u32(rng.gen()).expect("Generate BigNum failed");
        let serial_number = Asn1Integer::from_bn(random_serial).expect("Generate Asn1Integer failed");
        builder
            .set_serial_number(&serial_number)
            .expect("Set X509 serial number failed");
        let certificate: X509 = builder.build();

        let builder = Pkcs12::builder();
        let pkcs12 = builder
            .build(&self.password, &tax_id, &pkey, &certificate)
            .expect("Generate Pkcs12 failed");
        pkcs12.to_der().expect("Serialize Pkcs12 to DER failed")
    }
}
