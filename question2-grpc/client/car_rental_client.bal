import ballerina/io;
import ballerinax/grpc;


/*
 A simple demo client for the CarRental gRPC service.
 It's organized into small helper functions so it's readable and easy to tweak.
*/

public function main() returns error? {
    string target = "http://localhost:9090";
    car_rental_pb:CarRentalClient client = check new(target);

    io:println("Starting Car Rental client demo...");

    // create some users via client-streaming
    check createSampleUsers(client);

    // add a couple of cars (admin style)
    check addSampleCars(client);

    // list available cars (server-streaming)
    check showAvailableCars(client);

    // try a quick search
    check searchForCar(client, "ABC-123");

    // add a rental request to the cart for user u1
    check addItemToCart(client, "u1", "ABC-123", "2025-09-25T00:00:00Z", "2025-09-27T00:00:00Z");

    // place reservation for u1
    check placeReservationForUser(client, "u1");

    io:println("Client demo finished. Bye!");
    return;
}

function createSampleUsers(car_rental_pb:CarRentalClient client) returns error? {
    io:println("[createSampleUsers] streaming users to server...");
    stream<car_rental_pb:User, grpc:Error?> userStream = new;
    // a few example users
    check userStream->send({ id: "u1", name: "Alice", email: "alice@example.com", role: car_rental_pb:UserRole.ROLE_CUSTOMER });
    check userStream->send({ id: "admin1", name: "Admin", email: "admin@example.com", role: car_rental_pb:UserRole.ROLE_ADMIN });
    check userStream->send({ id: "u2", name: "Bob", email: "bob@example.com", role: car_rental_pb:UserRole.ROLE_CUSTOMER });
    check userStream->complete();

    car_rental_pb:CreateUsersResponse resp = check client->CreateUsers(userStream);
    io:println("[createSampleUsers] server responded: created=" + resp.created.toString() + ", message=\"" + resp.message + "\"");
    return;
}

function addSampleCars(car_rental_pb:CarRentalClient client) returns error? {
    io:println("[addSampleCars] adding two cars...");
    var r1 = check client->AddCar({
        car: {
            plate: "ABC-123",
            make: "Toyota",
            model: "Corolla",
            year: 2020,
            daily_price: 30.0,
            mileage: 50000,
            status: car_rental_pb:CarStatus.AVAILABLE
        }
    });
    io:println("[addSampleCars] " + r1.message);

    var r2 = check client->AddCar({
        car: {
            plate: "XYZ-999",
            make: "Honda",
            model: "Civic",
            year: 2019,
            daily_price: 28.0,
            mileage: 42000,
            status: car_rental_pb:CarStatus.AVAILABLE
        }
    });
    io:println("[addSampleCars] " + r2.message);
    return;
}

function showAvailableCars(car_rental_pb:CarRentalClient client) returns error? {
    io:println("[showAvailableCars] requesting available cars...");
    stream<car_rental_pb:Car, grpc:Error?> s = check client->ListAvailableCars({ text: "" });

    // print each car as it arrives
    check s.forEach(function (car_rental_pb:Car c) {
        // be forgiving about field types (generator may map enums differently)
        io:println("  -> " + c.plate + " | " + c.make + " " + c.model + " | price/day: " + c.daily_price.toString());
    });

    io:println("[showAvailableCars] done.");
    return;
}

function searchForCar(car_rental_pb:CarRentalClient client, string plate) returns error? {
    io:println("[searchForCar] looking for plate: " + plate);
    car_rental_pb:SearchCarResponse res = check client->SearchCar({ plate: plate });
    if res.found {
        io:println("[searchForCar] found: " + res.car.make + " " + res.car.model + " (" + res.car.plate + ")");
    } else {
        io:println("[searchForCar] not found -> " + res.message);
    }
    return;
}

function addItemToCart(
        car_rental_pb:CarRentalClient client,
        string userId,
        string plate,
        string startDate,
        string endDate) returns error? {

    io:println("[addItemToCart] user=" + userId + ", plate=" + plate);
    car_rental_pb:AddToCartResponse resp = check client->AddToCart({
        user_id: userId,
        plate: plate,
        start_date: startDate,
        end_date: endDate
    });
    io:println("[addItemToCart] ok=" + resp.ok.toString() + ", msg=\"" + resp.message + "\"");
    return;
}

function placeReservationForUser(car_rental_pb:CarRentalClient client, string userId) returns error? {
    io:println("[placeReservationForUser] placing reservation for " + userId + " ...");
    car_rental_pb:PlaceReservationResponse resp = check client->PlaceReservation({
        id: userId,
        name: "",
        email: "",
        role: car_rental_pb:UserRole.ROLE_CUSTOMER
    });
    if resp.ok {
        io:println("[placeReservationForUser] success! total_price=" + resp.total_price.toString());
    } else {
        io:println("[placeReservationForUser] failed -> " + resp.message);
    }
    return;
}
