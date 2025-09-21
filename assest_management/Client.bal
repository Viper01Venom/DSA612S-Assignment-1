import ballerina/http;
import ballerina/io;

public function main() returns error? {
    http:Client clientEP = check new ("http://localhost:8080/assets");

    // Add asset
    json assetPayload = {
        "assetTag": "EQ-001",
        "name": "3D Printer",
        "faculty": "Computing & Informatics",
        "department": "Software Engineering",
        "status": "ACTIVE",
        "acquiredDate": "2024-03-10",
        "components": {},
        "schedules": {},
        "workOrders": {}
    };
    http:Response addResp = check clientEP->post("/", assetPayload);
    io:println("Added asset: " + addResp.getTextPayload().toString());

    // Update asset
    json updatePayload = {
        "assetTag": "EQ-001",
        "name": "Updated 3D Printer",
        "faculty": "Computing & Informatics",
        "department": "Software Engineering",
        "status": "UNDER_REPAIR",
        "acquiredDate": "2024-03-10",
        "components": {},
        "schedules": {},
        "workOrders": {}
    };
    http:Response updateResp = check clientEP->put("/EQ-001", updatePayload);
    io:println("Updated asset: " + updateResp.getTextPayload().toString());

    // View all assets
    json allAssets = check clientEP->get("/");
    io:println("All assets: " + allAssets.toJsonString());

    // View by faculty
    json facultyAssets = check clientEP->get("/faculty/Computing & Informatics");
    io:println("Assets by faculty: " + facultyAssets.toJsonString());

    // Add schedule (for overdue demo)
    json schPayload = {
        "id": "SCH-001",
        "frequency": "quarterly",
        "nextDueDate": "2025-01-01" // Past date for overdue
    };
    http:Response addSchResp = check clientEP->post("/EQ-001/schedules", schPayload);
    io:println("Added schedule: " + addSchResp.getTextPayload().toString());

    // Overdue check
    json overdue = check clientEP->get("/overdue");
    io:println("Overdue assets: " + overdue.toJsonString());

    // Manage component
    json compPayload = {
        "id": "COMP-001",
        "name": "Motor"
    };
    http:Response addCompResp = check clientEP->post("/EQ-001/components", compPayload);
    io:println("Added component: " + addCompResp.getTextPayload().toString());

    // Delete component
    http:Response delCompResp = check clientEP->delete("/EQ-001/components/COMP-001");
    io:println("Deleted component: Status " + delCompResp.statusCode.toString());
}
