package com.budget.budget.services;

import com.budget.budget.model.AddSpend;
import com.budget.budget.model.UserData;
import com.budget.budget.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

@Service
public class UserServices {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    public boolean createUserTable(String username) {
        try {

            String tableName = "expenses_" + username;
            String createTableSQL = "CREATE TABLE IF NOT EXISTS " + tableName + " ("
                    + "id INT AUTO_INCREMENT PRIMARY KEY, "
                    + "spendAmt VARCHAR(255), "
                    + "place VARCHAR(255), "
                    + "category VARCHAR(50), "
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
            String tableName = "expenses_" + username;

            String insertTableSQL = "INSERT INTO " + tableName + " (spendAmt, place, category) VALUES ('" +
                    addSpend.getSpendAmt() + "', '" +
                    addSpend.getPlace() + "', '" +
                    addSpend.getCategory() + "');";

            jdbcTemplate.execute(insertTableSQL);
            return true;

        } catch (Exception e) {
            System.out.println("Error adding spend: " + e.getMessage());
            return false;
        }
    }

    public double getTotalSpend(String username) {
        try {
            String tableName = "expenses_" + username;
            String sql = "SELECT SUM(spendAmt) FROM " + tableName;
            Double sum = jdbcTemplate.queryForObject(sql, Double.class);
            System.out.println(sum);
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

            // Fetch both income (budget) and name from the database
            return jdbcTemplate.queryForObject(getBudgetSQL, new Object[]{email}, (rs, rowNum) -> {
                double budget = rs.getDouble("income");
                String name = rs.getString("name");

                double totalSpend = getTotalSpend(username);
                double remainingBalance = budget - totalSpend;

                return new String[]{String.valueOf(remainingBalance), name}; // Return remaining balance and name
            });
        } catch (Exception e) {
            System.out.println("Error fetching remaining balance and name: " + e.getMessage());
            return new String[]{"0.0", "Unknown"}; // Return a default value in case of error
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
}
