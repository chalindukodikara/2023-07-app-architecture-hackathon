import ballerina/io;
import ballerinax/googleapis.sheets as sheets;
import ballerina/http;
import ballerina/time;

configurable string refreshToken = ?;
configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string spreadsheetId = ?;
configurable string sheetName = ?;
configurable string visitStatAPIUrl = ?;
configurable string visitStatAPITokenURL = ?;
configurable string visitStatAPIConsumerKey = ?;
configurable string visitStatAPIConsumerSecret = ?;

// Configuring Google Sheets API
sheets:ConnectionConfig spreadsheetConfig = {
    auth: {
        clientId: clientId,
        clientSecret: clientSecret,
        refreshUrl: sheets:REFRESH_URL,
        refreshToken: refreshToken
    }
};

// A record to store PR/issue related data
public type Details record {
    string date;
    string inTime;
    string outTime;
    string houseNumber;
    string visitorName;
    string visitorNic;
    string vehicleNumber;
    string visitorPhone;
    string comment;
};

type VisitSvcResponse record {|
    string comment;
    string houseNo;
    string inTime;
    boolean isApproved;
    string outTime;
    string visitDate;
    string visitorName;
    int visitId;
    string visitorNIC;
    string vehicleNumber;
    string visitorPhoneNo;
|};

sheets:Client spreadsheetClient = check new (spreadsheetConfig);


public function insertVisit(VisitSvcResponse visit) {
    error? append = spreadsheetClient->appendRowToSheet(spreadsheetId, sheetName,
    [visit.visitDate, visit.inTime, visit.outTime, visit.houseNo, visit.visitorName, visit.visitorNIC, visit.vehicleNumber, visit.visitorPhoneNo, visit.comment]);
}

public function main() {
    // Clearing the sheet
    error? clearAllBySheetName = spreadsheetClient->clearAllBySheetName(spreadsheetId, sheetName);
    error? append = spreadsheetClient->appendRowToSheet(spreadsheetId, sheetName,
    ["Date", "In Time", "Out Time", "House", "Visitor Name", "Visitor NIC", "Vehicle Number", "Visitor Phone", "Comment"]);


    http:Client|error visitClient = new (visitStatAPIUrl,
        auth = {
            tokenUrl: visitStatAPITokenURL,
            clientId: visitStatAPIConsumerKey,
            clientSecret: visitStatAPIConsumerSecret,
            scopes: ["resident", "security"],
            username: "resident1@gmail.com",
            password: "Resident1@",
            optionalParams: {accessToken: "eyJ4NXQiOiJZVGxsTVRnelltSXhZamM0TXpGallqRmpNbU15T1dOak5qVTBOR0V6TURFME1HSmpaV1JrWldNeFlqRmhaVEU1T0dJeE5UVmhaR014Tnpoa016WmhaUSIsImtpZCI6IllUbGxNVGd6WW1JeFlqYzRNekZqWWpGak1tTXlPV05qTmpVME5HRXpNREUwTUdKalpXUmtaV014WWpGaFpURTVPR0l4TlRWaFpHTXhOemhrTXpaaFpRX1JTMjU2IiwidHlwIjoiYXQrand0IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiIzYWViYTE0OC01OGNiLTRhYmUtYmY3YS03YWVkMjdhY2I0NjQiLCJhdXQiOiJBUFBMSUNBVElPTiIsImF1ZCI6WyJ1eTljdFB4V1hpeERoa1NMNTJHZ3c5R1NicnNhIiwiY2hvcmVvOmRlcGxveW1lbnQ6cHJvZHVjdGlvbiJdLCJuYmYiOjE2OTEwMzY0NjcsImF6cCI6InV5OWN0UHhXWGl4RGhrU0w1MkdndzlHU2Jyc2EiLCJvcmdfaWQiOiIyYzZjM2M2ZS1mYTY1LTRlOGQtODk0My0yMTUyMTQ4ODdlYzgiLCJpc3MiOiJodHRwczpcL1wvYXBpLmFzZ2FyZGVvLmlvXC90XC9jaG9yZW9wbGF5Z3JvdW5kXC9vYXV0aDJcL3Rva2VuIiwiZXhwIjoxNjkxMDM3MzY3LCJvcmdfbmFtZSI6ImNob3Jlb3BsYXlncm91bmQiLCJpYXQiOjE2OTEwMzY0NjcsImp0aSI6IjhkODE3MGNmLWZmMGMtNDZkNS1iM2YwLTJjODlkMDI5MGQ4YiIsImNsaWVudF9pZCI6InV5OWN0UHhXWGl4RGhrU0w1MkdndzlHU2Jyc2EifQ.BMaelJNa7iGxVtckLagtE-Lpl3lM0wLDEkGDMpdRAYLiEtnZzgqLwxkMThw6YrDLOUjNRfdsYVYjHDUII24SDv_mfniZtTLaqdZpCP3lih6pCJSx8ABDzj79TpIv1FnF_05ct477XCmVInSBVr63_HKPLRWt22JgdtH7sBdC4DggCvd1YvrlVrjxSpRu4Ao_kmtfiPKAOyVGGKVc9Nzr_Icg8bMiZ2HvhrhbH1bmwsKkwCcl3Kfeq7FiPDemwvM8mANauR1hrIsutL-Orc4dUxIvEgJUBE7D4nphzd4K1ccgQX74q8SOGw2kszeqqtY5rPjPsnaaPGoP9PwHqCsSNQ"}
            
        }
    );
    if visitClient is error {
        io:println("Error while initializing the client.");
        return;
    }

    VisitSvcResponse[]|error visitResponse = visitClient->/actualVisits;
    if visitResponse is error {
        io:println("Error while getting the response.", visitResponse);
        return;
    }
    foreach VisitSvcResponse visit in visitResponse {
        time:Utc|error visitDate = time:utcFromString(visit.visitDate);
        if visitDate is error {
            io:println("Date is not in the expected format", visitResponse);
            continue;
        } else {
            // time:Utc currentTime = time:utcNow();
            // time:Utc startTime = utcSubtractSeconds(currentTime, 60 * 60);
            // if (visitDate < startTime) {
            //     continue;
            // }
            //commenting as date returned by the API is very old
        }

        error? insertDetailResponse = insertVisit(visit);
        if (insertDetailResponse is error) {
            io:println("Error while inserting the data.", insertDetailResponse);
            return;
        }
        io:println("Published a visit ", visit.visitId);
    }

    io:println("Successfully inserted the data.");
}

function utcSubtractSeconds(time:Utc utc, int seconds) returns time:Utc {
    [int, decimal] [secondsFromEpoch, lastSecondFraction] = utc;
    secondsFromEpoch = secondsFromEpoch - seconds;
    return [secondsFromEpoch, lastSecondFraction];
}