# Car Rental gRPC System (Question 2)

This is our attempt at building a small **Car Rental system** using gRPC and Ballerina.  
We split the work into three parts: proto (the contract), server, and client.  

## Files in this project
- `proto/car_rental.proto` → the proto file (defines all the messages and the service)  
- `server/car_rental_service.bal` → the server code (handles all the requests, keeps data in memory)  
- `client/car_rental_client.bal` → the client code (sends requests to test the server)  

## What the system does
We kept it simple with just two roles:
- **ADMIN** → can add, update, and remo
