# DSA612S Assignment 1 — REST and gRPC (Ballerina)

This repository contains our group project for Assignment 1.  
We implemented both **Question 1 (REST)** and **Question 2 (gRPC)** using Ballerina.  

## Group Members
- Mazilliano De Klerk — 220038872  
- Dyrall Beukes — 223058467  
- AJay Steyn — 222082429  
- Aden Beukes — 221138072  

---

## Project Structure

### Question 1 — Asset Management (REST)
Folder: `assest_management/`  
Files inside:
- `ballerina.toml`  
- `client.bal`  
- `server.bal`  

This is a RESTful service that allows managing assets.  
The server exposes REST endpoints, and the client demonstrates how to add, update, and query assets.

---

### Question 2 — Car Rental (gRPC)
Folder: `question2-grpc/`  
Structure:
- `proto/` → proto contract (`car_rental.proto`)  
- `server/` → gRPC server (`car_rental_service.bal`)  
- `client/` → gRPC client (`car_rental_client.bal`)  

This is a gRPC service for a car rental system.  
It supports admin operations (add/update/remove cars) and customer operations (list/search cars, add to cart, place reservations).

