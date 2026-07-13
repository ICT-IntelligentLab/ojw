package com.thomas;

import org.junit.jupiter.api.Test;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;

public class JDBCTest {

    @Test
    public void testUpdate() throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection root = DriverManager.getConnection("jdbc:mysql://localhost:3306/db01", "root", "1234");


        Statement statement = root.createStatement();
        String sql = "update user set username = 1000 where id = 1";
        int i = statement.executeUpdate(sql);
        System.out.println(i);

        statement.close();
        root.close();
    }

}
