package com.employee.controller;

import com.employee.model.Employee;
import com.employee.service.EmployeeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/employees")
@CrossOrigin(origins = "*")
public class EmployeeController {

    @Autowired
    private EmployeeService service;

    @GetMapping
    public List<Employee> getAll() { return service.getAllEmployees(); }

    @GetMapping("/{id}")
    public ResponseEntity<Employee> getById(@PathVariable Long id) {
        return service.getById(id).map(ResponseEntity::ok).orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public Employee create(@RequestBody Employee employee) { return service.create(employee); }

    @PutMapping("/{id}")
    public Employee update(@PathVariable Long id, @RequestBody Employee employee) {
        return service.update(id, employee);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/search")
    public List<Employee> search(@RequestParam String name) { return service.searchByName(name); }

    @GetMapping("/department/{dept}")
    public List<Employee> byDepartment(@PathVariable String dept) { return service.getByDepartment(dept); }

    @GetMapping("/info")
    public Map<String, String> info() {
        return Map.of("app", "Employee Management API", "version", "1.0.0", "status", "running");
    }
}
