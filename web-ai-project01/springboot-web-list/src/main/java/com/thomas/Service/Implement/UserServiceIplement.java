package com.thomas.Service.Implement;

import com.thomas.Dao.Implement.UserDaoImplement;
import com.thomas.Dao.UserDao;
import com.thomas.Service.UserService;
import com.thomas.pojo.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Component
public class UserServiceIplement implements UserService {

    @Autowired
    private UserDao userDao;
    @Override
    public List<User> list() {
        List<String> list = userDao.list();
        List<User> list1 = list.stream().map(item -> {
            String[] split = item.split(",");
            Integer id = Integer.parseInt(split[0]);
            String username = split[1];
            String password = split[2];
            String name = split[3];
            Integer age = Integer.parseInt(split[4]);
            LocalDateTime updateTime = LocalDateTime.parse(split[5], DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            return new User(id, username, password, name, age, updateTime);
        }).toList();
        return list1;
    }
}
