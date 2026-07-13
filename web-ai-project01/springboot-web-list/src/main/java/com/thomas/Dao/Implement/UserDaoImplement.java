package com.thomas.Dao.Implement;

import cn.hutool.core.io.IoUtil;
import com.thomas.Dao.UserDao;
import org.springframework.stereotype.Component;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

@Component
public class UserDaoImplement implements UserDao {
    @Override
    public List<String> list() {
        InputStream inputStream = this.getClass().getClassLoader().getResourceAsStream("user.txt");

        ArrayList<String> list = IoUtil.readLines(inputStream, "UTF-8", new ArrayList<>());

        return list;
    }
}
