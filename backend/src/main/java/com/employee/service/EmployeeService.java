package com.employee.service;

import com.employee.model.Employee;
import com.employee.repository.EmployeeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Optional;

@Service
public class EmployeeService {

    @Autowired
    private EmployeeRepository repository;

    public List<Employee> getAllEmployees() { return repository.findAll(); }

    public Optional<Employee> getById(Long id) { return repository.findById(id); }

    public Employee create(Employee employee) { return repository.save(employee); }

    public Employee update(Long id, Employee updated) {
        return repository.findById(id).map(emp -> {
            emp.setName(updated.getName());
            emp.setDepartment(updated.getDepartment());
            emp.setSalary(updated.getSalary());
            emp.setEmail(updated.getEmail());
            return repository.save(emp);
        }).orElseThrow(() -> new RuntimeException("Employee not found: " + id));
    }

    public void delete(Long id) { repository.deleteById(id); }

    public List<Employee> searchByName(String name) {
        return repository.findByNameContainingIgnoreCase(name);
    }

    public List<Employee> getByDepartment(String dept) {
        return repository.findByDepartment(dept);
    }
}
