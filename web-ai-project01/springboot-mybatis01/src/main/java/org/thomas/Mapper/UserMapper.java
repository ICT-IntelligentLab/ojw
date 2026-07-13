package org.thomas.Mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;
import org.thomas.pojo.User;

import java.util.List;

@Mapper
public interface UserMapper {

    @Select("select * from user")
    public List<User> findAll();
}
