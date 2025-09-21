import ballerina/io;
import ballerinax/grpc;


public function main() returns error? {
    string url = "http://localhost:9090";
    car_rental_pb:CarRentalServiceClient client = check new (url);

    io:println("=== Car Rental Client Demo ===");

    // 1) Create some users (client-streaming)
    io:println("\n-- Creating users --");
    stream<car_rental_pb:User, grpc:Error?> userStream = new;
    check userStream->send({id: "admin1", name: "Admin", role: "ADMIN", email: "admin@example.com"});
    check userStream->send({id: "u1", name: "Alice", role: "CUSTOMER", email: "alice@example.com"});
    check userStream->send({id: "u2", name: "Bob", role: "CUSTOMER", email: "bob@example.com"});
    check userStream->complete();

    car_rental_pb:CreateUsersResponse cuResp = check client->create_users(userStream);
    io:println("CreateUsers -> " + cuResp.message);

    // 2) Admin adds cars
    io:println("\n-- Adding cars --");
    var addResp1 = check client->add_car({
        plate: "ABC-123",
        make: "Toyota",
        model: "Corolla",
        year: 2020,
        daily_price: 30.0,
        mileage: 50000,
        status: "AVAILABLE",
        context: {user_id: "admin1"}
    });
    io:println("AddCar 1 -> " + addResp1.message);

    var addResp2 = check client->add_car({
        plate: "XYZ-999",
        make: "Honda",
        model: "Civic",
        year: 2019,
        daily_price: 28.0,
        mileage: 42000,
        status: "AVAILABLE",
        context: {user_id: "admin1"}
    });
    io:println("AddCar 2 -> " + addResp2.message);

    // 3) Customer lists available cars
    io:println("\n-- Listing available cars (customer u1) --");
    stream<car_rental_pb:Car, error?> availStream = 
        check client->list_available_cars({context: {user_id: "u1"}});
    check availStream.forEach(function(car_rental_pb:Car c) {
        io:println("Available: " + c.plate + " " + c.make + " " + c.model + " $" + c.daily_price.toString());
    });

    // 4) Search for a car
    io:println("\n-- Search for ABC-123 (customer u1) --");
    car_rental_pb:CarResponse searchResp = 
        check client->search_car({plate: "ABC-123", context: {user_id: "u1"}});
    io:println("SearchCar -> " + searchResp.message);

    // 5) Add to cart
    io:println("\n-- Add to cart (u1 adds ABC-123) --");
    car_rental_pb:StatusResponse cartResp = check client->add_to_cart({
        user_id: "u1",
        plate: "ABC-123",
        start_date: "2025-09-25",
        end_date: "2025-09-27"
    });
    io:println("AddToCart -> " + cartResp.message);

    // 6) Place reservation
    io:println("\n-- Place reservation (u1) --");
    car_rental_pb:ReservationResponse resResp = check client->place_reservation({
        user_id: "u1"
    });
    io:println("Reservation -> " + resResp.message);
    if resResp.reservation is car_rental_pb:Reservation {
        io:println("Reservation id: " + resResp.reservation.id + 
            " total: " + resResp.reservation.total_price.toString());
    }

    io:println("\n=== Demo done ===");
}
