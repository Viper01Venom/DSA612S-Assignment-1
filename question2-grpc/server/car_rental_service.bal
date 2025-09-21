import ballerina/grpc;
import ballerina/log;

// In-memory stores
map<Car> cars = {};
map<User> users = {};
map<map<CartItem>> carts = {}; // user_id -> map<plate, CartItem>
map<Reservation> reservations = {};

listener grpc:Listener ep = new (9090);

@grpc:ServiceDescriptor {descriptor: ROOT_DESCRIPTOR_CAR_RENTAL}
service "CarRentalService" on ep {

    remote function add_car(Car value) returns CarResponse|error {
        if !users.hasKey(value.context.user_id ?: "") || users.get(value.context.user_id ?: "").role != "ADMIN" {
            return {message: "Unauthorized"};
        }
        cars[value.plate] = value;
        return {car: value, message: "Car added"};
    }

    remote function create_users(stream<User, grpc:Error?> clientStream) returns CreateUsersResponse|error {
        check clientStream.forEach(function(User u) {
            users[u.id] = u;
            carts[u.id] = {};
        });
        return {message: "Users created"};
    }

    remote function update_car(Car value) returns CarResponse|error {
        if !users.hasKey(value.context.user_id ?: "") || users.get(value.context.user_id ?: "").role != "ADMIN" {
            return {message: "Unauthorized"};
        }
        if cars.hasKey(value.plate) {
            cars[value.plate] = value;
            return {car: value, message: "Car updated"};
        }
        return {message: "Car not found"};
    }

    remote function remove_car(RemoveCarRequest value) returns stream<Car, error?>|error {
        if !users.hasKey(value.context.user_id ?: "") || users.get(value.context.user_id ?: "").role != "ADMIN" {
            return error("Unauthorized");
        }
        if cars.hasKey(value.plate) {
            _ = cars.remove(value.plate);
        }
        return from var c in cars select c;
    }

    remote function list_available_cars(ListAvailableRequest value) returns stream<Car, error?>|error {
        if !users.hasKey(value.context.user_id ?: "") || users.get(value.context.user_id ?: "").role != "CUSTOMER" {
            return error("Unauthorized");
        }
        return from var c in cars
               where c.status == "AVAILABLE"
               select c;
    }

    remote function search_car(SearchCarRequest value) returns CarResponse|error {
        if !users.hasKey(value.context.user_id ?: "") || users.get(value.context.user_id ?: "").role != "CUSTOMER" {
            return {message: "Unauthorized"};
        }
        if cars.hasKey(value.plate) && cars.get(value.plate).status == "AVAILABLE" {
            return {car: cars.get(value.plate), message: "Found"};
        }
        return {message: "Not available"};
    }

    remote function add_to_cart(CartItem value) returns StatusResponse|error {
        if !users.hasKey(value.user_id) || users.get(value.user_id).role != "CUSTOMER" {
            return {message: "Unauthorized"};
        }
        if cars.hasKey(value.plate) {
            carts[value.user_id][value.plate] = value;
            return {message: "Added to cart"};
        }
        return {message: "Car not found"};
    }

    remote function place_reservation(PlaceReservationRequest value) returns ReservationResponse|error {
        if !users.hasKey(value.user_id) || users.get(value.user_id).role != "CUSTOMER" {
            return {message: "Unauthorized"};
        }
        map<CartItem> userCart = carts.get(value.user_id);
        if userCart.length() == 0 {
            return {message: "Cart empty"};
        }
        double total = 0.0;
        foreach var item in userCart {
            if cars.get(item.plate).status == "AVAILABLE" {
                total += 2 * cars.get(item.plate).daily_price; // Simple 2-day estimate
                cars.get(item.plate).status = "UNAVAILABLE";
            } else {
                return {message: "Car unavailable"};
            }
        }
        string resId = "RES-" + value.user_id;
        Reservation res = {id: resId, user_id: value.user_id, items: userCart.toArray(), total_price: total};
        reservations[resId] = res;
        carts[value.user_id] = {};
        return {reservation: res, message: "Reservation placed"};
    }
}
