import XCTest
import Persona2
@testable import PersonaPlugin

final class PersonaErrorMapperTests: XCTestCase {
    func testNetworkingErrorProducesMessageAndCodeWithoutCause() {
        let payload = PersonaErrorMapper.payload(for: .networking)

        XCTAssertEqual(payload["errorCode"] as? String, "networking")
        XCTAssertEqual(payload["error"] as? String, PersonaError.networking.debugDescription)
        XCTAssertFalse((payload["error"] as? String ?? "").isEmpty)
        XCTAssertNil(payload["cause"])
    }

    func testMisconfiguredErrorCarriesConfigurationDetailAsCause() {
        let detail = InquiryConfigurationError.invalidTemplateId("itmpl_bad")

        let payload = PersonaErrorMapper.payload(for: .misconfigured(detail))

        XCTAssertEqual(payload["errorCode"] as? String, "misconfigured")
        XCTAssertEqual(payload["cause"] as? String, detail.localizedDescription)
        XCTAssertFalse((payload["cause"] as? String ?? "").isEmpty)
    }

    func testEveryKnownCaseMapsToAStableCode() {
        let expectations: [(PersonaError, String)] = [
            (.networking, "networking"),
            (.invalidSessionToken, "invalidSessionToken"),
            (.oneTimeLinkCodeInvalid, "oneTimeLinkCodeInvalid"),
            (.rateLimitExceeded, "rateLimitExceeded"),
            (.camera, "camera"),
            (.gps, "gps"),
            (.permissions, "permissions"),
            (.misconfigured(.serverConfiguration), "misconfigured"),
            (.other, "other")
        ]

        for (error, expectedCode) in expectations {
            XCTAssertEqual(PersonaErrorMapper.code(for: error), expectedCode, "\(error)")
        }
    }
}
