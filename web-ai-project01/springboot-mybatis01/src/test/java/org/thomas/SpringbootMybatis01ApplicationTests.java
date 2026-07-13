package org.thomas;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.thomas.Mapper.UserMapper;

@SpringBootTest
class SpringbootMybatis01ApplicationTests {

    @Autowired
    private UserMapper userMapper;
    @Test
    public void testFindAll() {
        System.out.println(userMapper.findAll());
    }

}
