package com.budget.budget.model;

public class AddSpend {

    String spendAmt;
    String place;
    String category;
    String username;

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getSpendAmt() {
        return spendAmt;
    }

    public void setSpendAmt(String spendAmt) {
        this.spendAmt = spendAmt;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public String getPlace() {
        return place;
    }

    public void setPlace(String place) {
        this.place = place;
    }
}
