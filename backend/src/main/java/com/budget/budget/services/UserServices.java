package com.budget.budget.services;

import com.budget.budget.model.AddSpend;
import com.budget.budget.model.Participant;
import com.budget.budget.model.UserData;
import com.budget.budget.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class UserServices {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    public boolean createUserTable(String username) {
        try {
            String createTableSQL = "CREATE TABLE IF NOT EXISTS " + username + " ("
                    + "id INT AUTO_INCREMENT PRIMARY KEY, "
                    + "spendAmt VARCHAR(255), "
                    + "place VARCHAR(255), "
                    + "category VARCHAR(50), "
                    + "payeruser VARCHAR(50), "
                    + "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
                    + ")";
            jdbcTemplate.execute(createTableSQL);
            return true;
        } catch (Exception e) {
            System.out.println("Error creating table: " + e.getMessage());
            return false;
        }
    }

    public boolean addSpend(AddSpend addSpend, String username) {
        try {
            String insertTableSQL = "INSERT INTO " + username + " (spendAmt, place, category,payeruser) VALUES ('" +
                    addSpend.getSpendAmt() + "', '" +
                    addSpend.getPlace() + "', '" +
                    addSpend.getCategory() + "', '" +
                    "myself" + "');";
            jdbcTemplate.execute(insertTableSQL);
            return true;
        } catch (Exception e) {
            System.out.println("Error adding spend: " + e.getMessage());
            return false;
        }
    }

    public double getTotalSpend(String username) {
        try {
            String sql = "SELECT SUM(spendAmt) FROM " + username;
            Double sum = jdbcTemplate.queryForObject(sql, Double.class);
            return (sum != null) ? sum : 0.0;
        } catch (Exception e) {
            System.out.println("Error fetching total spend: " + e.getMessage());
            return 0.0;
        }
    }

    public String[] getRemainingBalance(String username) {
        try {
            String email = username + "@gmail.com";
            String getBudgetSQL = "SELECT income, name FROM user_details WHERE email = ?";
            return jdbcTemplate.queryForObject(getBudgetSQL, new Object[]{email}, (rs, rowNum) -> {
                double budget = rs.getDouble("income");
                String name = rs.getString("name");
                double totalSpend = getTotalSpend(username);
                double remainingBalance = budget - totalSpend;
                return new String[]{String.valueOf(remainingBalance), name};
            });
        } catch (Exception e) {
            System.out.println("Error fetching remaining balance and name: " + e.getMessage());
            return new String[]{"0.0", "Unknown"};
        }
    }

    public UserData authenticate(String email, String password) {
        return userRepository.findByEmailAndPassword(email, password).orElse(null);
    }

    public UserData findByEmail(String email) {
        return userRepository.findByEmail(email).orElse(null);
    }

    public void saveUser(UserData userData) {
        userRepository.save(userData);
    }

    public boolean splitExpense(String payerUsername,String place,String category, double totalAmount, List<String> participants) {
        try {
            // Calculate each participant's share
            String splitUser = payerUsername.substring(0, payerUsername.indexOf('@'));
            double splitAmount = totalAmount / (participants.size() + 1);
            addUser(splitUser, splitAmount,place,category,"myself");

            // Update the balance for each participant except the payer
            for (String participantUsername : participants) {
                if (!participantUsername.equals(payerUsername)) {
                    String username = participantUsername.substring(0, participantUsername.indexOf('@'));
                    addUser(username, splitAmount,place,category,splitUser);
                }
            }
            return true;
        } catch (Exception e) {
            System.out.println("Error splitting expense: " + e.getMessage());
            return false;
        }
    }


    public boolean addUser(String username, double initialOwedAmount,String place,String category,String payerUser) {
        String insertUserSQL = "INSERT INTO "+username+" (spendAmt,place,category,payeruser) VALUES (?,?,?,?)";

        try {
            int rowsAffected = jdbcTemplate.update(insertUserSQL, initialOwedAmount,place,category,payerUser);
            return rowsAffected > 0; // Return true if the insert was successful
        } catch (Exception e) {
            System.out.println("Error adding user: " + e.getMessage());
            return false; // Return false in case of an error
        }
    }


}
