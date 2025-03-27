[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/xtremedev)
[![Liberapay](https://img.shields.io/badge/Liberapay-F6C915?logo=liberapay&logoColor=black)](https://liberapay.com/XTREME)

> [!WARNING]
> This app is in very early development, you can use it, however please be warned that there could be bugs, and data loss, please make sure to backup your data, and use at your own risk.

> [!CAUTION]
> If you are using Android, and your device has been rooted, it is advised against storing any sensitive information on the device, including 2FA secrets, we cannot protect against in-memory attacks, or rogue Xposed modules, or anything else like that.

> [!NOTE]
> Open2FA is currently only available in English, please consider helping translate Open2FA into your language, see the [Translations](#translations) section for more information.
>
> Also, I am looking for an icon for Open2FA, if you have an icon submission, please make an issue with the icon, and I will take a look at it.

# Open2FA

Open2FA is a Free and Open Source 2FA (Two Factor Authentication) app, which is available for Android, Windows, and Linux. It is made using Flutter, once finished, I will try to release it on F-Droid, and possibly the Google Play Store, if I can get it on the Play Store, it may be a paid app to help fund the project, but anyone who wants it for free can get it from F-Droid, use Obtainium, or build it themselves.

## Why Open2FA?

Open2FA collects no data, no analytics, no crash reports, nothing, we do not collect or store any user data, your data is your data.
We are fully open-source and believe in the power of open-source software, and the freedom it provides.

## Support for iOS

iOS support may be added in the future, but I do not have a Mac, or a Apple Developer account, and I also do not plan on paying Apple $100/year to release a free app on their store.
If you want to use Open2FA on iOS, and you have a Mac, and a way to sign the app, for example using Signulous, then you can build it yourself, and sign it, and use it on your device.

If you would like to see Open2FA on iOS, please consider donating to help me cover the costs of a Mac, and a Apple Developer account.

## Support For Passkeys

> [!NOTE]
> Physical security keys like Yubikeys are recommended over passkeys, and TOTP, if you have the option of using a physical security key, then you should use one.

Passkeys may eventually be supported in Open2FA, but it is not a priority, and may not be added for a while, if at all.
When I have some time, I may look into adding support for passkeys.
This may not even be a possibility due to the limitations of Flutter, and possibly Android itself.

## Security

> [!NOTE]
> I am not a security expert, cryptographer, or anything like that, I am just a developer who is trying to make a secure app, if you see any issues, please let me know, and if possible, please suggest a fix, or make a PR, I will do my best to fix any issues that are found.

Open2FA uses the Argon2id KDF, using the [OWASP recommendation of 9 MiB memory, 4 iterations, and 1 parallelism](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html#argon2id) and a randomly generated 32 byte salt.
To enable biometric unlock, we have to store the encryption key persistently, this is done via Flutter Secure Storage.
The account secret, issuer, label, and categories are all encrypted at rest, using XChaCha20-Poly1305, with a key dervied from the user's password, using Argon2id as described above.
Along with encrypting the account data, we also encrypt the database itself via SQLCipher, as a security precaution, we use a key derived from the account data encryption key, just incase the key for the database is ever leaked when passed to SQLCipher.

To validate the password without attempting to decrypt the database every time, we store an Argon2id hash in the Flutter Secure Storage, and compare it to the hash of the password when the user tries to unlock the app.

When the user chooses no authentication, we generate a secure random 32 bytes, base64 encode it, and use it as a password, this is stored in the Flutter Secure Storage, and is used to derive the encryption key, and the database key from the encryption key.

Encrypted exports use the same encryption as the account data, but with a different key, derived from a password entered at the time of export, this password is never stored, and is only used to derive the key for the export. 

## Translations

> [!NOTE]
> Make sure to update the `manifest.json` if you are adding a new language.

If you would like to help translate Open2FA, you can do so by making a PR with the translations.
All translations are stored under the `i18n/` directory, and are in the format of `languageCode.json`, for example, `en_gb.json`, `fr.json`, etc.
For languages that have multiple dialects, please use the language code, and the dialect code, for example, `en_us.json`, `en_gb.json`, etc.

## Contributing

> [!NOTE]
> Please make sure that any changes you make work on all platforms, and do not break anything, if you are unsure, please ask before making a PR.
>
> Also, ensure that your code is formatted using LF line endings, and that you have run `dart format ./lib/**/*.dart` before making a PR.

If you would like to contribute to Open2FA via code, you can fork the repo, make your changes, and make a PR to the dev branch.
Before opening a PR, please make sure you understand that your code will be licensed under the GPL-3.0 License, and that you are okay with that.

## Export Format

There are 2 available formats for exporting your data, JSON, Encrypted JSON.
The encrypted JSON format uses XChaCha20-Poly1305, using the Argon2id KDF, with the same parameters as described in [Security](#security).
This is an example of the JSON format:

```json
{
  "encrypted": false,
  "db": {
	"categories": [
		{
			"uuid": "3cffa94e-b8c7-4461-b4d6-7fa69cf88bbb",
			"name": "Example",
			"updated_at": "2022-01-01T00:00:00.000Z",
			"created_at": "2022-01-01T00:00:00.000Z"
		}
	],
	"accounts": [
		{
		"label": "user@example.com",
		"issuer": "Example",
		"secret": "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ",
		"algorithm": "SHA1",
		"type": "totp",
		"digits": 6,
		"interval": 30,
		"google": true,
		"categories": [],
		"updated_at": "2022-01-01T00:00:00.000Z",
		"created_at": "2022-01-01T00:00:00.000Z"
		},
		{
		"label": "user2@example.com",
		"issuer": "Example",
		"secret": "JBSWY3DPEHPK3PXP",
		"algorithm": "SHA512",
		"type": "hotp",
		"digits": 8,
		"counter": 1,
		"google": true,
		"categories": ["3cffa94e-b8c7-4461-b4d6-7fa69cf88bbb"],
		"updated_at": "2022-01-01T00:00:00.000Z",
		"created_at": "2022-01-01T00:00:00.000Z"
		}
	]
  }
}
```

This is what the encrypted JSON format looks like:

```jsonc
{
  "encrypted": true,
  "passwordHash": "{encoded hash}", // $argon2id$v={version}$m={memory},t={iterations},p={parallelism}${base64 encoded salt}${base64 encoded hash}
  // Salt for the encryption key itself (same Argon2id parameters as the password hash)
  "salt": "{base64 encoded salt}",
  "nonce": "{base64 encoded nonce}",
  "mac": "{base64 encoded mac}",
  "db": "{base64 encoded encrypted db}"
}
```

## GitHub Stars

[![Star History Chart](https://api.star-history.com/svg?repos=XTREME1738/Open2FA&type=Date)](https://www.star-history.com/#XTREME1738/Open2FA&Date)