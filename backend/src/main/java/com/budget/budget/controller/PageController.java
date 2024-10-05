package com.budget.budget.controller;


import com.budget.budget.model.AddSpend;
import com.budget.budget.model.UserData;
import com.budget.budget.services.UserServices;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;


@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class PageController {

    @Autowired
    UserServices userService;

    @Autowired
    private BCryptPasswordEncoder passwordEncoder;

    @PostMapping("/login")
    public ResponseEntity<String> loginUser(@RequestBody UserData userData) {
        String email = userData.getEmail();
        String password = userData.getPassword();

        UserData existingUser = userService.findByEmail(email);

        if (existingUser == null) {
            return new ResponseEntity<>("User not found", HttpStatus.NOT_FOUND);
        }

        if (passwordEncoder.matches(password, existingUser.getPassword())) {
            return new ResponseEntity<>("Login successful", HttpStatus.OK);
        } else {
            return new ResponseEntity<>("Invalid email or password", HttpStatus.UNAUTHORIZED);
        }
    }

    @PostMapping("/register")
    public ResponseEntity<String> registerUser(@RequestBody UserData userData) {

        if (userService.findByEmail(userData.getEmail()) != null) {
            return new ResponseEntity<>("Email already exists", HttpStatus.BAD_REQUEST);
        }

        userData.setPassword(passwordEncoder.encode(userData.getPassword()));

        String email = userData.getEmail();
        String username = email.substring(0, email.indexOf('@'));

        if (userService.createUserTable(username)) {

            userService.saveUser(userData);
            return new ResponseEntity<>("User registered successfully", HttpStatus.CREATED);
        } else {
            return new ResponseEntity<>("Error creating user table", HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @PostMapping("/add-spend")
    public ResponseEntity<String> addSpend(@RequestBody AddSpend addSpend) {
        String username = addSpend.getUsername().substring(0, addSpend.getUsername().indexOf('@'));

        boolean isAdded = userService.addSpend(addSpend, username);
        if (isAdded) {
            return ResponseEntity.ok("Spend added successfully.");
        } else {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Error adding spend.");
        }
    }

    @GetMapping("/dashboard/{username}")
    public ResponseEntity<Map<String, String>> getDashboardData(@PathVariable String username) {
        String totalSpend = String.valueOf(userService.getTotalSpend(username));

        String[] data = userService.getRemainingBalance(username);
        String remainingBalance = data[0];
        String name = data[1];

        Map<String, String> dashboardData = new HashMap<>();
        dashboardData.put("totalSpend", totalSpend);
        dashboardData.put("remainingBalance", remainingBalance);
        dashboardData.put("userName", name);

        return ResponseEntity.ok(dashboardData);
    }




}
