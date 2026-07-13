package com.thomas.controller;

import com.thomas.Service.UserService;
import com.thomas.pojo.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.List;

@RestController
public class UserController {

        @Autowired
        private UserService userService;
        @RequestMapping("/list")
        public List<User> list(){
            List<User> list = userService.list();
            return list;
        }
}
