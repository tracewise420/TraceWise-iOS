import XCTest
@testable import TraceWiseSDK

final class DigitalLinkParserTests: XCTestCase {
    
    func testParseValidDigitalLinkWithAllAIs() throws {
        let url = "https://id.gs1.org/01/09506000134352/21/SN12345/10/BATCH001/17/251231"
        let result = try DigitalLinkParser.parse(url)
        
        XCTAssertEqual(result.gtin, "09506000134352")
        XCTAssertEqual(result.serial, "SN12345")
        XCTAssertEqual(result.batch, "BATCH001")
        XCTAssertEqual(result.expiry, "251231")
    }
    
    func testParseDigitalLinkGTINOnly() throws {
        let url = "https://id.gs1.org/01/04012345678905"
        let result = try DigitalLinkParser.parse(url)
        
        XCTAssertEqual(result.gtin, "04012345678905")
        XCTAssertNil(result.serial)
        XCTAssertNil(result.batch)
        XCTAssertNil(result.expiry)
    }
    
    func testParseDigitalLinkWithSerial() throws {
        let url = "https://id.gs1.org/01/04012345678905/21/SN123456"
        let result = try DigitalLinkParser.parse(url)
        
        XCTAssertEqual(result.gtin, "04012345678905")
        XCTAssertEqual(result.serial, "SN123456")
        XCTAssertNil(result.batch)
        XCTAssertNil(result.expiry)
    }
    
    func testParseInvalidDigitalLink() {
        let url = "https://example.com/invalid"
        
        XCTAssertThrowsError(try DigitalLinkParser.parse(url)) { error in
            guard case TraceWiseError.invalidDigitalLink = error else {
                XCTFail("Expected invalidDigitalLink error")
                return
            }
        }
    }
    
    func testParseDigitalLinkWithInvalidGTIN() {
        let url = "https://id.gs1.org/01/123" // Invalid GTIN (not 14 digits)
        
        XCTAssertThrowsError(try DigitalLinkParser.parse(url)) { error in
            guard case TraceWiseError.invalidDigitalLink = error else {
                XCTFail("Expected invalidDigitalLink error")
                return
            }
        }
    }
}