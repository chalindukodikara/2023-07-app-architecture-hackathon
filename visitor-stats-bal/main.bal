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
// configurable string usernameScope = ?;
// configurable string passwordScope = ?;
// configurable string[] scopesAPI = ?;

// configurable string refreshToken = "1//04x4QDZJ9g3yXCgYIARAAGAQSNwF-L9IrGNAwDV657zfuTH4GFjIi-iAzgQBlZofh-QSqoZMFReweV4VM3EPSCEo2Q55-zdG9JA8";
// configurable string clientId = "1020932192395-92dc5upu0ltgntvfjhkk5ut4p6roggdu.apps.googleusercontent.com";
// configurable string clientSecret = "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";
// configurable string spreadsheetId = "1LDqFosOh9i_QQtyw63RY81Yn7E2eCAt4LzwUgZl2ep0";
// configurable string sheetName = "visitorstats";
// configurable string visitStatAPIUrl = "https://2c6c3c6e-fa65-4e8d-8943-215214887ec8-dev.e1-us-east-azure.choreoapis.dev/zrvn/chalinduvisitapi/visit-420/1.0.0";
// configurable string visitStatAPITokenURL = "https://api.asgardeo.io/t/choreoplayground/oauth2/token";
// configurable string visitStatAPIConsumerKey = "vHDlS7rtcgEDR0OXZktxW9NLBi4a";
// configurable string visitStatAPIConsumerSecret = "ThoKlxm98RMV2Fd9j6PDX3WIdXW1mefwvvVB22TS8X0a";
// configurable string usernameScope = "resident1@gmail.com";
// configurable string passwordScope = "Resident1@";
// configurable string[] scopesAPI = ["urn:choreoplayground:chalinduvisitapivisit420:resident", "urn:choreoplayground:chalinduvisitapivisit420:security"];


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
                clientSecret: visitStatAPIConsumerSecret

            }

    // http:Client|error visitClient = new (visitStatAPIUrl,
    //     auth = {
    //         tokenUrl: visitStatAPITokenURL,
    //         clientId: visitStatAPIConsumerKey,
    //         clientSecret: visitStatAPIConsumerSecret,
    //         scopes: scopesAPI,
    //         username: usernameScope,
    //         password: passwordScope

    //     }
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