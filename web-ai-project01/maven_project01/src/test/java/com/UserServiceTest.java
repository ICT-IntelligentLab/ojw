package com;


import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;


@DisplayName("测试类")
public class UserServiceTest {

    @Test
    public void testGetAge() {
        UserService userService = new UserService();
        Integer age = userService.getAge("100000200210173814");
        System.out.println(age);
    }

    @Test
    public void testGetGender() {
        UserService userService = new UserService();
        String gender = userService.getGender("100000200210173814");
        System.out.println(gender);
    }

    @ParameterizedTest
    @ValueSource(strings = {"100000200210173814","100000200210173834","100000200210173854"})
    public void testGenderWithAssert(String id) {
        UserService userService = new UserService();
        String gender = userService.getGender(id);
        Assertions.assertEquals("男", gender, "error");
    }

    @Test
    public void testGenderWithAssert2() {
        UserService userService = new UserService();
        String gender = userService.getGender("100000200210173814");
        Assertions.assertThrows(IllegalArgumentException.class, () -> {userService.getGender(null);});
    }


}
