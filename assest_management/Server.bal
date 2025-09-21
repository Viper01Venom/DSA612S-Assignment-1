import ballerina/http;
import ballerina/time;
import ballerina/log;

// Define enums and records
public enum Status {
    ACTIVE,
    UNDER_REPAIR,
    DISPOSED
}

public type Component record {|
    string id;
    string name;
    string description?;
|};

public type Schedule record {|
    string id;
    string frequency; // e.g., "quarterly", "yearly"
    string nextDueDate; // ISO date string, e.g., "2025-12-01"
|};

public type Task record {|
    string id;
    string description;
    boolean completed = false;
|};

public type WorkOrder record {|
    string id;
    string status; // e.g., "OPEN", "CLOSED"
    Task[] tasks = [];
|};

public type Asset record {|
    string assetTag;
    string name;
    string faculty;
    string department;
    Status status;
    string acquiredDate;
    map<Component> components = {};
    map<Schedule> schedules = {};
    map<WorkOrder> workOrders = {};
|};

// In-memory database
map<Asset> assets = {};

// HTTP Service
service /assets on new http:Listener(8080) {

    // Create asset (POST /assets)
    resource function post .(@http:Payload Asset newAsset) returns Asset|http:BadRequest {
        if assets.hasKey(newAsset.assetTag) {
            return http:BAD_REQUEST;
        }
        assets[newAsset.assetTag] = newAsset;
        return newAsset;
    }

    // Get all assets (GET /assets)
    resource function get .() returns Asset[] {
        return assets.toArray();
    }

    // Get asset by tag (GET /assets/{tag})
    resource function get [string tag]() returns Asset|http:NotFound {
        if assets.hasKey(tag) {
            return assets.get(tag);
        }
        return http:NOT_FOUND;
    }

    // Update asset (PUT /assets/{tag})
    resource function put [string tag](@http:Payload Asset updatedAsset) returns Asset|http:NotFound|http:BadRequest {
        if !assets.hasKey(tag) {
            return http:NOT_FOUND;
        }
        if tag != updatedAsset.assetTag {
            return http:BAD_REQUEST;
        }
        assets[tag] = updatedAsset;
        return updatedAsset;
    }

    // Delete asset (DELETE /assets/{tag})
    resource function delete [string tag]() returns http:NoContent|http:NotFound {
        if assets.hasKey(tag) {
            _ = assets.remove(tag);
            return http:NO_CONTENT;
        }
        return http:NOT_FOUND;
    }

    // Get assets by faculty (GET /assets/faculty/{faculty})
    resource function get faculty/[string faculty]() returns Asset[] {
        return from Asset a in assets
               where a.faculty == faculty
               select a;
    }

    // Get overdue assets (GET /assets/overdue)
    resource function get overdue() returns Asset[] {
        time:Utc now = time:utcNow();
        string currentDate = time:utcToCivil(now).toString().substring(0, 10); // YYYY-MM-DD

        return from Asset a in assets
               from Schedule s in a.schedules
               where s.nextDueDate < currentDate
               select a;
    }

    // Add component to asset (POST /assets/{tag}/components)
    resource function post [string tag]/components(@http:Payload Component comp) returns Component|http:NotFound|http:BadRequest {
        if !assets.hasKey(tag) {
            return http:NOT_FOUND;
        }
        Asset a = assets.get(tag);
        if a.components.hasKey(comp.id) {
            return http:BAD_REQUEST;
        }
        a.components[comp.id] = comp;
        return comp;
    }

    // Remove component (DELETE /assets/{tag}/components/{compId})
    resource function delete [string tag]/components/[string compId]() returns http:NoContent|http:NotFound {
        if !assets.hasKey(tag) {
            return http:NOT_FOUND;
        }
        Asset a = assets.get(tag);
        if a.components.hasKey(compId) {
            _ = a.components.remove(compId);
            return http:NO_CONTENT;
        }
        return http:NOT_FOUND;
    }

    // Add schedule (POST /assets/{tag}/schedules)
    resource function post [string tag]/schedules(@http:Payload Schedule sch) returns Schedule|http:NotFound|http:BadRequest {
        if !assets.hasKey(tag) {
            return http:NOT_FOUND;
        }
        Asset a = assets.get(tag);
        if a.schedules.hasKey(sch.id) {
            return http:BAD_REQUEST;
        }
        a.schedules[sch.id] = sch;
        return sch;
    }

    // Remove schedule (DELETE /assets/{tag}/schedules/{schId})
    resource function delete [string tag]/schedules/[string schId]() returns http:NoContent|http:NotFound {
        if !assets.hasKey(tag) {
            return http:NOT_FOUND;
        }
        Asset a = assets.get(tag);
        if a.schedules.hasKey(schId) {
            _ = a.schedules.remove(schId);
            return http:NO_CONTENT;
        }
        return http:NOT_FOUND;
    }

    // Add work order (POST /assets/{tag}/workOrders)
    resource function post [string tag]/workOrders(@http:Payload WorkOrder wo) returns WorkOrder|http:NotFound|http:BadRequest {
        if !assets.hasKey(tag) {
            return http:NOT_FOUND;
        }
        Asset a = assets.get(tag);
        if a.workOrders.hasKey(wo.id) {
            return http:BAD_REQUEST;
        }
        a.workOrders[wo.id] = wo;
        return wo;
    }

    // Update work order (PUT /assets/{tag}/workOrders/{woId})
    resource function put [string tag]/workOrders/[string woId](@http:Payload WorkOrder updatedWo) returns WorkOrder|http:NotFound|http:BadRequest {
        if !assets.hasKey(tag) {
            return http:NOT_FOUND;
        }
        Asset a = assets.get(tag);
        if !a.workOrders.hasKey(woId) {
            return http:NOT_FOUND;
        }
        if woId != updatedWo.id {
            return http:BAD_REQUEST;
        }
        a.workOrders[woId] = updatedWo;
        return updatedWo;
    }

    // Add task to work order (POST /assets/{tag}/workOrders/{woId}/tasks)
    resource function post [string tag]/workOrders/[string woId]/tasks(@http:Payload Task task) returns Task|http:NotFound|http:BadRequest {
        if !assets.hasKey(tag) {
            return http:NOT_FOUND;
        }
        Asset a = assets.get(tag);
        if !a.workOrders.hasKey(woId) {
            return http:NOT_FOUND;
        }
        WorkOrder wo = a.workOrders.get(woId);
        foreach Task t in wo.tasks {
            if t.id == task.id {
                return http:BAD_REQUEST;
            }
        }
        wo.tasks.push(task);
        return task;
    }

    // Remove task (DELETE /assets/{tag}/workOrders/{woId}/tasks/{taskId})
    resource function delete [string tag]/workOrders/[string woId]/tasks/[string taskId]() returns http:NoContent|http:NotFound {
        if !assets.hasKey(tag) {
            return http:NOT_FOUND;
        }
        Asset a = assets.get(tag);
        if !a.workOrders.hasKey(woId) {
            return http:NOT_FOUND;
        }
        WorkOrder wo = a.workOrders.get(woId);
        int? index = ();
        foreach int i in 0..<wo.tasks.length() {
            if wo.tasks[i].id == taskId {
                index = i;
                break;
            }
        }
        if index is int {
            _ = wo.tasks.remove(index);
            return http:NO_CONTENT;
        }
        return http:NOT_FOUND;
    }
}

function init() {
    log:printInfo("Asset Management Service started on port 8080");
}